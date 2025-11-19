# frozen_string_literal: true

module Blacklight
  ##
  # SearchBuilder is the primary search builder for generating main search result queries.
  # It converts Blacklight request parameters into query parameters appropriate for the
  # search index by evaluating a chain of processing methods.
  #
  # ## When to Use SearchBuilder
  #
  # Use SearchBuilder (or extend it) for:
  # - **Main search results pages** - The primary search interface users see
  # - **Advanced search** - Complex multi-field search forms
  #
  # SearchBuilder handles common search functionality like:
  # - Query parsing and field searching
  # - Facet filtering and constraints
  # - Pagination (rows, start, page)
  # - Sorting and result ordering
  # - Field selection for display
  #
  # ## Typical Usage Patterns
  #
  # Most applications will extend SearchBuilder to add custom query logic:
  #
  #   class SearchBuilder < Blacklight::SearchBuilder
  #     include Blacklight::Solr::SearchBuilderBehavior
  #
  #     # Add custom processor to the chain
  #     self.default_processor_chain += [:add_institution_filter]
  #
  #     def add_institution_filter(solr_parameters)
  #       return unless current_user&.institution
  #       solr_parameters[:fq] ||= []
  #       solr_parameters[:fq] << "institution_id:#{current_user.institution.id}"
  #     end
  #   end
  #
  # ## When NOT to Use SearchBuilder
  #
  # Don't use SearchBuilder for:
  # - **Facet queries** - Use {Blacklight::FacetSearchBuilder} instead
  # - **Single document retrieval** - Use repository methods directly
  # - **Specialized admin queries** - Consider extending {AbstractSearchBuilder}
  #
  # ## Important: Query Parameter Customizations
  #
  # **If your customizations modify Solr's `q` or `fq` parameters, you likely need
  # to add the same logic to both SearchBuilder AND FacetSearchBuilder.**
  #
  # This is because facet queries inherit the same base query context as search results.
  # For example, if you add an institution filter to search results, users would expect
  # facet values to also be filtered by that same institution:
  #
  #   # Add to BOTH SearchBuilder and FacetSearchBuilder
  #   def add_institution_filter(solr_parameters)
  #     return unless current_user&.institution
  #     solr_parameters[:fq] ||= []
  #     solr_parameters[:fq] << "institution_id:#{current_user.institution.id}"
  #   end
  #
  # Common parameters that affect both builders:
  # - Access control filters (`fq`)
  # - Institution or tenant scoping (`fq`)
  # - Date range constraints (`fq`)
  # - Status filtering (published, active, etc.) (`fq`)
  # - Query modifications that change search scope (`q`)
  #
  # ## Processor Chain Methods
  #
  # When including `Blacklight::Solr::SearchBuilderBehavior`, you get these processors:
  # - `default_solr_parameters` - Base configuration defaults
  # - `add_query_to_solr` - Main user query (q parameter)
  # - `add_facet_fq_to_solr` - Applied facet filters
  # - `add_facetting_to_solr` - Facet field configuration
  # - `add_paging_to_solr` - Pagination (rows, start)
  # - `add_sorting_to_solr` - Sort parameters
  # - `add_solr_fields_to_query` - Field lists (fl parameter)
  #
  class SearchBuilder < AbstractSearchBuilder
    ##
    # Update the :q (query) parameter
    # @param [Hash<Symbol,Object>] conditions the field and values to query on
    # @example
    #    search_builder.where(id: [1,2,3]) # produces: q:"{!lucene}id:(1 OR 2 OR 3)"
    def where(conditions)
      params_will_change!
      @search_state = @search_state.reset(@search_state.params.merge(q: conditions))
      @blacklight_params = @search_state.params
      @additional_filters = conditions
      self
    end

    ##
    # Append additional processor chain directives
    # This is used in blacklight_range_limit
    def append(*addl_processor_chain)
      params_will_change!
      builder = self.class.new(processor_chain + addl_processor_chain, scope)
                    .with(search_state)
                    .merge(@merged_params)
                    .reverse_merge(@reverse_merged_params)

      builder.start = @start if @start
      builder.rows  = @rows if @rows
      builder.page  = @page if @page
      builder.facet = @facet if @facet
      builder
    end

    ##
    # Converse to append, remove processor chain directives,
    # returning a new builder that's a copy of receiver with
    # specified change.
    #
    # Methods in argument that aren't currently in processor
    # chain are ignored as no-ops, rather than raising.
    def except(*except_processor_chain)
      builder = self.class.new(processor_chain - except_processor_chain, scope)
                    .with(search_state)
                    .merge(@merged_params)
                    .reverse_merge(@reverse_merged_params)

      builder.start = @start if @start
      builder.rows  = @rows if @rows
      builder.page  = @page if @page
      builder.facet = @facet if @facet
      builder
    end

    def start=(value)
      params_will_change!
      @start = value.to_i
    end

    # @param [#to_i] value
    def start(value = nil)
      if value
        self.start = value
        return self
      end
      @start ||= (page - 1) * (rows || 10)
      val = @start || 0
      val = 0 if @start < 0
      val
    end
    alias_method :padding, :start

    def page=(value)
      params_will_change!
      @page = value.to_i
      @page = 1 if @page < 1
    end

    # @param [#to_i] value
    def page(value = nil)
      if value
        self.page = value
        return self
      end
      @page ||= search_state.page
    end

    def rows=(value)
      params_will_change!
      @rows = [value, blacklight_config.max_per_page].map(&:to_i).min
    end

    # @param [#to_i] value
    def rows(value = nil)
      if value
        self.rows = value
        return self
      end
      @rows ||= begin
        # user-provided parameters should override any default row
        r = search_state.per_page
        # ensure we don't excede the max page size
        r.nil? ? nil : [r, blacklight_config.max_per_page].map(&:to_i).min
      end
    end

    alias per rows

    # Decode the user provided 'sort' parameter into a sort string that can be
    # passed to the search.  This sanitizes the input by ensuring only
    # configured search values are passed through to the search.
    # @return [String] the field/fields to sort by
    def sort
      search_state.sort_field&.sort
    end
  end
end
