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
        views.keys.length > 1
      end

      def icon(view)
        @view_context.render_view_type_group_icon(view)
      end

      def label(view)
        view_config = blacklight_config.view[view]

        t(
          :"blacklight.search.view_title.#{view}",
          default: [
            :"blacklight.search.view.#{view}",
            view_config.label,
            view_config.title,
            view.to_s.humanize
          ]
        )
      end

      def url(view)
        @view_context.url_for(@search_state.to_h.merge(view: view))
      end
    end
  end
end
