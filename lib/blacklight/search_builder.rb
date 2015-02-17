module Blacklight
  class SearchBuilder
    extend Deprecation
    self.deprecation_horizon = "blacklight 6.0"

    attr_reader :blacklight_params

    # @param [Hash,HashWithIndifferentAccess] user_params the user provided parameters (e.g. query, facets, sort, etc)
    # @param [List<Symbol>] processor_chain a list of filter methods to run
    # @param [Object] scope the scope where the filter methods reside in.
    def initialize(*args)
      if args.length == 3
        Deprecation.warn Blacklight::SearchBuilder, "Blacklight::SearchBuilder#initialize with user_params argument is deprecated; use #with(user_params) instead"
        @user_params, @processor_chain, @scope = args
      elsif args.length == 2
        @processor_chain, @scope = args
      else
        raise ArgumentError.new "Wrong number of arguments (#{args.length} for 2)"
      end
    end

    def with blacklight_params
      @blacklight_params = blacklight_params
      self
    end

    # a solr query method
    # @param [Hash,HashWithIndifferentAccess] extra_controller_params (nil) extra parameters to add to the search
    # @return [Blacklight::SolrResponse] the solr response object
    def query(extra_params = nil)
      extra_params ? processed_parameters.merge(extra_params) : processed_parameters
    end

    # @returns a params hash for searching solr.
    # The CatalogController #index action uses this.
    # Solr parameters can come from a number of places. From lowest
    # precedence to highest:
    #  1. General defaults in blacklight config (are trumped by)
    #  2. defaults for the particular search field identified by  params[:search_field] (are trumped by)
    #  3. certain parameters directly on input HTTP query params
    #     * not just any parameter is grabbed willy nilly, only certain ones are allowed by HTTP input)
    #     * for legacy reasons, qt in http query does not over-ride qt in search field definition default.
    #  4.  extra parameters passed in as argument.
    #
    # spellcheck.q will be supplied with the [:q] value unless specifically
    # specified otherwise.
    #
    # Incoming parameter :f is mapped to :fq solr parameter.
    def processed_parameters
      Blacklight::Solr::Request.new.tap do |request_parameters|
        @processor_chain.each do |method_name|
          if @scope.respond_to?(method_name, true)
            Deprecation.warn Blacklight::SearchBuilder, "Building search parameters by calling #{method_name} on #{@scope.to_s}. This behavior will be deprecated in Blacklight 6.0"
            @scope.send(method_name, request_parameters, @user_params)
          else
            send(method_name, request_parameters)
          end
        end
      end
    end

    def blacklight_config
      @scope.blacklight_config
    end

    protected
    def page
      blacklight_params[:page].to_i unless blacklight_params[:page].blank?
    end

    def rows default = nil
      # user-provided parameters should override any default row
      rows = blacklight_params[:rows].to_i unless blacklight_params[:rows].blank?
      rows = blacklight_params[:per_page].to_i unless blacklight_params[:per_page].blank?

      default ||= blacklight_config.default_per_page
      default ||= 10
      rows ||= default

      # ensure we don't excede the max page size
      rows = blacklight_config.max_per_page if rows.to_i > blacklight_config.max_per_page


      rows
    end

    def sort
      field = if blacklight_params[:sort].blank? and sort_field = blacklight_config.default_sort_field
        # no sort param provided, use default
        sort_field.sort
      elsif sort_field = blacklight_config.sort_fields[blacklight_params[:sort]]
        # check for sort field key  
        sort_field.sort
      else 
        # just pass the key through
        blacklight_params[:sort]
      end

      field unless field.blank?
    end

    def search_field
      blacklight_config.search_fields[blacklight_params[:search_field]]
    end
    
    def should_add_field_to_request? field_name, field
      field.include_in_request || (field.include_in_request.nil? && blacklight_config.add_field_configuration_to_solr_request)
    end

  end
end
