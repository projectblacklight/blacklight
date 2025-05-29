# frozen_string_literal: true

# The Facetable module can be included onto classes that need to initialize a FacetSearchService.
# There are two dependencies you must provide on the including class. Typically these
# would be provided by Blacklight::Controller
#  1. search_state
#  2. blacklight_config
#
# Additionally, the including class may override the facet_search_service_context method to provide
# further context to the SearchService. For example you could override this to provide the
# currently signed in user.
module Blacklight::Facetable
  extend ActiveSupport::Concern

  included do
    # Which class to use for the search service. You can subclass SearchService if you
    # want to override any of the methods (e.g. SearchService#fetch)
    class_attribute :facet_search_service_class
    self.facet_search_service_class = Blacklight::FacetSearchService
  end

  # @return [Blacklight::FacetSearchService]
  def facet_search_service
    facet_search_service_class.new(config: blacklight_config, search_state: search_state, user_params: search_state.to_h, **facet_search_service_context)
  end

  # Override this method on the class that includes Blacklight::Facetable to provide more context to the search service if necessary.
  # For example, if your search builder needs to be aware of the current user, override this method to return a hash including the current user.
  # Then the search builder could use some property about the current user to construct a constraint on the search.
  # @return [Hash] a hash of context information to pass through to the search service
  def facet_search_service_context
    search_service_context
  end
end
