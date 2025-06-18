# frozen_string_literal: true

# FacetSearchService returns a facet list from the repository. This is for drawing the "more facets" modal
module Blacklight
  class FacetSearchService
    def initialize(config:, search_state:, search_builder_class: config.facet_search_builder_class, **context)
      @blacklight_config = config
      @search_state = search_state
      @user_params = @search_state.params
      @search_builder_class = search_builder_class
      @context = context
    end

    # The blacklight_config + controller are accessed by the search_builder
    attr_reader :blacklight_config, :context

    def search_builder
      search_builder_class.new(self)
    end

    def search_state_class
      @search_state.class
    end

    ##
    # Get the solr response when retrieving only a single facet field
    # @return [Blacklight::Solr::Response] the solr response
    def facet_field_response(facet_field, extra_controller_params = {})
      query = search_builder.with(search_state).facet(facet_field)
      repository.search(params: query.merge(extra_controller_params))
    end

    def facet_suggest_response(facet_field, facet_suggestion_query, extra_controller_params = {})
      query = search_builder.with(search_state).facet(facet_field).facet_suggestion_query(facet_suggestion_query)
      repository.search(params: query.merge(extra_controller_params))
    end

    private

    attr_reader :search_builder_class, :search_state

    delegate :repository, to: :blacklight_config
  end
end
