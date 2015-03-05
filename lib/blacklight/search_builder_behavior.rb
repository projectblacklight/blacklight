module Blacklight
  module SearchBuilderBehavior
    extend Deprecation
    self.deprecation_horizon = "blacklight 6.0"

    attr_reader :processor_chain, :blacklight_params

    # @param [List<Symbol>] processor_chain a list of filter methods to run
    # @param [Object] scope the scope where the filter methods reside in.
    def initialize(processor_chain, scope)
      @processor_chain = processor_chain
      @scope = scope
      @blacklight_params = {}
    end

    ##
    # Set the parameters to pass through the processor chain
    def with blacklight_params = {}
      @blacklight_params = blacklight_params.dup
      self
    end

    ##
    # Update the :q (query) parameter
    def where conditions
      @blacklight_params[:q] = conditions
      self
    end

    ##
    # Append additional processor chain directives
    def append *addl_processor_chain
      self.class.new(processor_chain + addl_processor_chain, scope).with(blacklight_params)
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
          if scope.respond_to?(method_name, true)
            Deprecation.warn Blacklight::SearchBuilderBehavior, "Building search parameters by calling #{method_name} on #{scope.class}. This behavior will be deprecated in Blacklight 6.0. Instead, define #{method_name} on a subclass of #{self.class} and set search_builder_class in the configuration"
            scope.send(method_name, request_parameters, blacklight_params)
          else
            send(method_name, request_parameters)
          end
        end
      end
    end

    def blacklight_config
      scope.blacklight_config
    end

    protected
    def page
      if blacklight_params[:page].blank?
        1
      else
        blacklight_params[:page].to_i
      end
    end

    def rows default = nil
      # default number of rows
      rows = default
      rows ||= blacklight_config.default_per_page
      rows ||= 10

      # user-provided parameters should override any default row
      rows = blacklight_params[:rows].to_i unless blacklight_params[:rows].blank?
      rows = blacklight_params[:per_page].to_i unless blacklight_params[:per_page].blank?

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

    protected
    def scope
      @scope
    end

  end
end
