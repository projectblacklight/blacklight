# frozen_string_literal: true

module Blacklight
  class SearchNavbarComponent < Blacklight::Component
    def initialize(blacklight_config:)
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config

    delegate :container_classes, to: :helpers

    def search_bar
      render search_bar_component
    end

    def search_bar_component
      search_bar_component_class.new(
        url: helpers.search_action_url,
        advanced_search_url: helpers.search_action_url(action: 'advanced_search'),
        params: helpers.search_state.params_for_search.except(:qt),
        autocomplete_path: suggest_index_catalog_path
      )
    end

    def search_bar_component_class
      view_config&.search_bar_component || Blacklight::SearchBarComponent
    end

    def view_config
      blacklight_config&.view_config(helpers.document_index_view_type)
    end
  end
end
