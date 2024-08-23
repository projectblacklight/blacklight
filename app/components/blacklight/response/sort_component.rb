# frozen_string_literal: true

module Blacklight
  module Response
    class SortComponent < Blacklight::Component
      def initialize(search_state:, param: 'sort', choices: {}, id: 'sort-dropdown', classes: [], selected: nil)
        @param = param
        @choices = choices
        @search_state = search_state
        @id = id
        @classes = classes
        @selected = selected
      end

      # You may override this method in a subclass if you want to use a different dropdown component
      def dropdown_class
        helpers.blacklight_config.view_config(:show).dropdown_component
      end

      def dropdown
        render(dropdown_class.new(
                 param: @param,
                 choices: @choices,
                 id: @id,
                 search_state: @search_state,
                 selected: @selected
               ))
      end
    end
  end
end
