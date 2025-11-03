# frozen_string_literal: true

module Blacklight
  ##
  # FacetSearchBuilder creates Solr queries specifically for facet-related operations,
  # particularly for "more facets" functionality where users want to see additional
  # facet values beyond what's displayed on the main search results page.
  #
  # ## When to Use FacetSearchBuilder
  #
  # Use FacetSearchBuilder for:
  # - **"More facets" pages** - When users click "more" to see additional facet values
  # - **Facet pagination** - Browsing through large lists of facet values
  # - **Facet suggestion/autocomplete** - Type-ahead search within facet values
  # - **Facet-only queries** - When you need facet data without search results
  #
  # ## Key Differences from SearchBuilder
  #
  # FacetSearchBuilder differs from SearchBuilder in several important ways:
  # - Sets `rows: 0` to avoid returning document results (only facets matter)
  # - Includes facet pagination parameters (`facet.offset`, `facet.limit`)
  # - Supports facet prefix filtering for suggestion queries
  # - Optimized processor chain focused on facet generation
  #
  # ## Typical Usage
  #
  # FacetSearchBuilder is typically used internally by Blacklight's facet controllers
  # and helpers, but you can extend it for custom facet behavior:
  #
  #   class FacetSearchBuilder < Blacklight::FacetSearchBuilder
  #     include Blacklight::Solr::FacetSearchBuilderBehavior
  #
  #     # Add custom facet filtering
  #     self.default_processor_chain += [:add_facet_security_filter]
  #
  #     def add_facet_security_filter(solr_parameters)
  #       return unless facet == 'institution_facet'
  #       solr_parameters[:fq] ||= []
  #       solr_parameters[:fq] << 'public:true'
  #     end
  #   end
  #
  # ## Processor Chain Methods
  #
  # When including `Blacklight::Solr::FacetSearchBuilderBehavior`, you get:
  # - All SearchBuilderBehavior processors (for base query building)
  # - `add_facet_paging_to_solr` - Handles facet pagination parameters
  # - `add_facet_suggestion_parameters` - Supports facet prefix/suggestion queries
  #
  # ## Important: Query Parameter Customizations
  #
  # **If your customizations modify Solr's `q` or `fq` parameters, you likely need
  # to add the same logic to both SearchBuilder AND FacetSearchBuilder.**
  #
  # This is critical because facet queries should reflect the same constraints as
  # the main search results. Users expect facet values to be filtered by the same
  # criteria that filter their search results:
  #
  #   # Add to BOTH SearchBuilder and FacetSearchBuilder
  #   def add_institution_filter(solr_parameters)
  #     return unless current_user&.institution
  #     solr_parameters[:fq] ||= []
  #     solr_parameters[:fq] << "institution_id:#{current_user.institution.id}"
  #   end
  #
  # Common parameters that typically need both builders:
  # - Access control filters (`fq`)
  # - Institution or tenant scoping (`fq`)
  # - Date range constraints (`fq`)
  # - Status filtering (published, active, etc.) (`fq`)
  # - Query scope modifications (`q`)
  #
  # ## When NOT to Use FacetSearchBuilder
  #
  # Don't use FacetSearchBuilder for:
  # - **Main search results** - Use {Blacklight::SearchBuilder} instead
  # - **Document display** - Use repository methods directly
  # - **General queries** - Use {SearchBuilder} or extend {AbstractSearchBuilder}
  #
  class FacetSearchBuilder < AbstractSearchBuilder
    def facet_suggestion_query=(value)
      params_will_change!
      @facet_suggestion_query = value
    end

    def facet_suggestion_query(value = nil)
      if value
        self.facet_suggestion_query = value
        return self
      end
      @facet_suggestion_query
    end
  end
end
