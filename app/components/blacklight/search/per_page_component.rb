# frozen_string_literal: true

module Blacklight
  module Search
    class PerPageComponent < Blacklight::Component
      def initialize(blacklight_config:, response:, search_state:)
        @blacklight_config = blacklight_config
        @response = response
        @search_state = search_state
      end

      def render?
        helpers.show_sort_and_per_page?
      end

      # You may override this method in a subclass if you want to use a different dropdown component
      def dropdown_class
        @blacklight_config.view_config(:show).dropdown_component
      end

      def dropdown
        render(dropdown_class.new(
                 param: :per_page,
                 choices: per_page_options_for_select,
                 id: 'per_page-dropdown',
                 search_state: @search_state,
                 selected: current_per_page,
                 interpolation: :count
               ))
      end

      #
      # @return [Integer]
      def current_per_page
        (@response.rows if @response && @response.rows > 0) || # rubocop:disable Style/NumericPredicate
          params.fetch(:per_page, @blacklight_config.default_per_page).to_i
      end

      ##
      # The available options for results per page, in the style of #options_for_select
      def per_page_options_for_select
        return [] if @blacklight_config.per_page.blank?

        @blacklight_config.per_page.map do |count|
          [t(:'blacklight.search.per_page.label', count: count).html_safe, count]
        end
      end
    end
  end
end
