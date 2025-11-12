# frozen_string_literal: true

##
# Application-level FacetSearchBuilder that extends Blacklight's base FacetSearchBuilder
# with Solr-specific functionality for facet queries.
#
# ## Purpose
#
# This class serves as your application's facet search builder for generating
# queries specifically for facet operations like "more facets" pages and facet
# pagination. It includes `Blacklight::Solr::FacetSearchBuilderBehavior` which
# provides a complete processor chain optimized for facet-only queries.
#
# ## When to Modify This Class
#
# Add custom facet logic here when you need to:
# - Filter facet values based on user permissions
# - Apply institution-specific facet constraints
# - Customize facet sorting or display logic
# - Add security filters to facet queries
# - Implement custom facet suggestion behavior
#
# ## Adding Custom Processors
#
# Extend the processor chain to add your own facet query building methods:
#
#   class FacetSearchBuilder < Blacklight::FacetSearchBuilder
#     include Blacklight::Solr::FacetSearchBuilderBehavior
#
#     # Add your custom processor to the chain
#     self.default_processor_chain += [:add_facet_access_control]
#
#     # Define the processor method
#     def add_facet_access_control(solr_parameters)
#       return unless facet == 'restricted_facet'
#       return unless current_user&.admin?
#       # Only show restricted facet values to admins
#       solr_parameters[:fq] ||= []
#       solr_parameters[:fq] << "access_level:admin"
#     end
#   end
#
# ## Key Differences from SearchBuilder
#
# FacetSearchBuilder queries differ from regular search queries:
# - Returns no document results (`rows: 0`)
# - Focuses on facet value generation and pagination
# - Supports facet prefix filtering for autocomplete
# - Optimized for facet-specific operations
#
# ## Important: Shared Query Logic
#
# **If your customizations modify Solr's `q` or `fq` parameters, you likely need
# to add the same logic to BOTH this FacetSearchBuilder AND SearchBuilder.**
#
# This ensures facet queries reflect the same constraints as search results:
#
#   class SearchBuilder < Blacklight::SearchBuilder
#     include Blacklight::Solr::SearchBuilderBehavior
#     self.default_processor_chain += [:add_institution_filter]
#
#     def add_institution_filter(solr_parameters)
#       return unless current_user&.institution
#       solr_parameters[:fq] ||= []
#       solr_parameters[:fq] << "institution_id:#{current_user.institution.id}"
#     end
#   end
#
#   class FacetSearchBuilder < Blacklight::FacetSearchBuilder
#     include Blacklight::Solr::FacetSearchBuilderBehavior
#     self.default_processor_chain += [:add_institution_filter]
#
#     # Same method needed here too!
#     def add_institution_filter(solr_parameters)
#       return unless current_user&.institution
#       solr_parameters[:fq] ||= []
#       solr_parameters[:fq] << "institution_id:#{current_user.institution.id}"
#     end
#   end
#
# ## Alternative Approaches
#
# - For main search results, use `SearchBuilder` instead
# - For completely different query patterns, extend `AbstractSearchBuilder`
# - For one-off modifications, use `append()` method on builder instances
#
class FacetSearchBuilder < Blacklight::FacetSearchBuilder
  include Blacklight::Solr::FacetSearchBuilderBehavior
end
