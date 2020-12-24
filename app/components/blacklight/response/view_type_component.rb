# frozen_string_literal: true

module Blacklight
  module Response
    # Render spellcheck results for a search query
    class ViewTypeComponent < ViewComponent::Base
      # @param [Blacklight::Response] response
      def initialize(response:, views: {}, search_state:, selected: nil)
        @response = response
        @views = views
        @search_state = search_state
        @selected = selected
      end

      def render?
        !@response.empty? && helpers.document_index_views.keys.length > 1
      end

      def icon(view)
        helpers.render_view_type_group_icon(view)
      end

      def label(view)
        view_config = helpers.blacklight_config.view[view]
        view_config.display_label(view)
      end

      def url(view)
        helpers.url_for(@search_state.to_h.merge(view: view))
      end
    end
  end
end
