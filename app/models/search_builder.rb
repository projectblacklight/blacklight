# frozen_string_literal: true

##
# Application-level SearchBuilder that extends Blacklight's base SearchBuilder
# with Solr-specific functionality.
#
# ## Purpose
#
# This class serves as your application's main search builder for generating
# search result queries. It includes `Blacklight::Solr::SearchBuilderBehavior`
# which provides a complete processor chain for Solr queries.
#
# ## When to Modify This Class
#
# Add custom search logic here when you need to:
# - Apply institution-specific filtering
# - Add custom faceting behavior
# - Implement access controls or permission filtering
# - Modify query parsing or field weighting
# - Add analytics or logging to search queries
#
# ## Adding Custom Processors
#
# Extend the processor chain to add your own query building methods:
#
#   class SearchBuilder < Blacklight::SearchBuilder
#     include Blacklight::Solr::SearchBuilderBehavior
#
#     # Add your custom processor to the chain
#     self.default_processor_chain += [:add_my_custom_filter]
#
#     # Define the processor method
#     def add_my_custom_filter(solr_parameters)
#       solr_parameters[:fq] ||= []
#       solr_parameters[:fq] << "status:published"
#     end
#   end
#
# ## Important: Shared Query Logic
#
# **If your customizations modify Solr's `q` or `fq` parameters, you likely need
# to add the same logic to BOTH this SearchBuilder AND FacetSearchBuilder.**
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
# - For facet-specific queries, extend `FacetSearchBuilder` instead
# - For completely different search patterns, extend `AbstractSearchBuilder`
# - For one-off modifications, use `append()` method on search builder instances
#
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
end
