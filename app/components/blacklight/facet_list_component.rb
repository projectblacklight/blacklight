# frozen_string_literal: true

module Blacklight
  ##
  # Renders the list of all facets
  class FacetListComponent < ViewComponent::Base
    # @param [Blacklight::Configuration] blacklight_config
    # @param [Blacklight::Solr::Response] response
    def initialize(blacklight_config:, response:)
      @blacklight_config = blacklight_config
      @response = response
    end
  end
end
