# frozen_string_literal: true

module Blacklight
  module Response
    # Render spellcheck results for a search query
    class ViewTypeComponent < Blacklight::Component
      renders_many :views, 'Blacklight::Response::ViewTypeButtonComponent'

      # @param [Blacklight::Response] response
      def initialize(response:, search_state:, views: {}, selected: nil)
        @response = response
        @views = views
        @search_state = search_state
        @selected = selected
      end

      def before_render
        return if views.any?

        @views.each do |key, config|
          with_view(key: key, view: config, selected: @selected == key, search_state: @search_state)
        end
      end

      def render?
        views.many? && !@response.empty?
      end
    end
  end
end
