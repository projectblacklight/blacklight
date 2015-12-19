module Blacklight
  ##
  # Blacklight's SearchBuilder converts blacklight request parameters into
  # query parameters appropriate for search index. It does so by evaluating a
  # chain of processing methods to populate a result hash (see {#to_hash}).
  class SearchBuilder
    extend Deprecation
    class_attribute :default_processor_chain
    self.default_processor_chain = []

    attr_reader :processor_chain, :blacklight_params

    # @param [List<Symbol>,TrueClass] options a list of filter methods to run or true, to use the default methods
    # @param [Object] scope the scope where the filter methods reside in.
    def initialize(*options)
      @scope = case options.size
      when 1
        options.first
      when 2
        if options.first === true
          Deprecation.warn Blacklight::SearchBuilder, "SearchBuilder#initialize now takes only one parameter, the scope. Passing `true' will be removed in Blacklight 7"
        else
          @processor_chain = options.first
        end
        options.last
      else
        raise ArgumentError, "wrong number of arguments. (#{options.size} for 1..2)"
      end

      @processor_chain ||= default_processor_chain.dup
      @blacklight_params = {}
      @merged_params = {}
      @reverse_merged_params = {}
    end

    ##
    # Set the parameters to pass through the processor chain
    def with blacklight_params = {}
      params_will_change!
      @blacklight_params = blacklight_params.dup
      self
    end

    ##
    # Update the :q (query) parameter
    def where conditions
      params_will_change!
      @blacklight_params[:q] = conditions
      self
    end

    ##
    # Append additional processor chain directives
    def append *addl_processor_chain
      params_will_change!
      builder = self.class.new(processor_chain + addl_processor_chain, scope)
          .with(blacklight_params)
          .merge(@merged_params)
          .reverse_merge(@reverse_merged_params)

      builder.start(@start) if @start
      builder.rows(@rows) if @rows
      builder.page(@page) if @page
      builder.facet(@facet) if @facet

      builder
    end

    ##
    # Converse to append, remove processor chain directives,
    # returning a new builder that's a copy of receiver with
    # specified change. 
    #
    # Methods in argument that aren't currently in processor
    # chain are ignored as no-ops, rather than raising. 
    def except *except_processor_chain
      builder = self.class.new(processor_chain - except_processor_chain, scope)
          .with(blacklight_params)
          .merge(@merged_params)
          .reverse_merge(@reverse_merged_params)

      builder.start(@start) if @start
      builder.rows(@rows) if @rows
      builder.page(@page) if @page
      builder.facet(@facet) if @facet

      builder
    end

    ##
    # Merge additional, repository-specific parameters
    def merge extra_params, &block
      if extra_params
        params_will_change!
        @merged_params.merge!(extra_params.to_hash, &block)
      end
      self
    end
    
    ##
    # "Reverse merge" additional, repository-specific parameters
    def reverse_merge extra_params, &block
      if extra_params
        params_will_change!
        @reverse_merged_params.reverse_merge!(extra_params.to_hash, &block)
      end
      self
    end

    delegate :[], :key?, to: :to_hash

    # a solr query method
    # @param [Hash] extra_controller_params (nil) extra parameters to add to the search
    # @return [Blacklight::Solr::Response] the solr response object
    def to_hash
      if params_need_update?
        @params = processed_parameters.
                    reverse_merge(@reverse_merged_params).
                    merge(@merged_params).
                    tap { self.clear_changes }
      else
        @params
      end
    end

    alias_method :query, :to_hash
    alias_method :to_h, :to_hash

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
      request.tap do |request_parameters|
        processor_chain.each do |method_name|
          send(method_name, request_parameters)
        end
      end
    end

    def blacklight_config
      scope.blacklight_config
    end

    def start start = nil
      if start
        params_will_change!
        @start = start.to_i
        self
      else
        @start ||= (page - 1) * (rows || 10)

        val = @start || 0
        val = 0 if @start < 0
        val
      end
    end
    alias_method :padding, :start

    def page page = nil
      if page
        params_will_change!
        @page = page.to_i
        @page = 1 if @page < 1
        self
      else
        @page ||= begin
          page = if blacklight_params[:page].blank?
            1
          else
            blacklight_params[:page].to_i
          end

          page
        end
      end
    end

    def rows rows = nil
      if rows
        params_will_change!
        @rows = rows.to_i
        @rows = blacklight_config.max_per_page if @rows > blacklight_config.max_per_page
        self
      else
        @rows ||= begin
          rows = blacklight_config.default_per_page

          # user-provided parameters should override any default row
          rows = blacklight_params[:rows].to_i unless blacklight_params[:rows].blank?
          rows = blacklight_params[:per_page].to_i unless blacklight_params[:per_page].blank?

          # ensure we don't excede the max page size
          rows = blacklight_config.max_per_page if rows.to_i > blacklight_config.max_per_page

          rows.to_i unless rows.nil?
        end
      end
    end

    alias_method :per, :rows

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

    # sets the facet that this query pertains to, if it is for the purpose of
    # facet pagination
    def facet(facet = nil)
      if facet
        params_will_change!
        @facet = facet
        self
      else
        @facet
      end
    end

    def search_field
      blacklight_config.search_fields[blacklight_params[:search_field]]
    end

    protected
    def request
      Blacklight::Solr::Request.new
    end

    def should_add_field_to_request? field_name, field
      field.include_in_request || (field.include_in_request.nil? && blacklight_config.add_field_configuration_to_solr_request)
    end

    def scope
      @scope
    end

    def params_will_change!
      @dirty = true
    end

    def params_changed?
      !!@dirty
    end

    def params_need_update?
      params_changed? || @params.nil?
    end

    def clear_changes
      @dirty = false
    end
  end
end
