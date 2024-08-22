# frozen_string_literal: true

module Blacklight
  module Response
    class SortComponent < ViewComponent::Base
      def initialize(param: 'sort', choices: {}, search_state:, id: 'sort-dropdown', classes: [], selected: nil)
        @param = param
        @choices = choices
        @search_state = search_state
        @id = id
        @classes = classes
        @selected = selected
      end

      # You may override this method in a subclass if you want to use a different dropdown component
      def dropdown_class
        Blacklight::System::DropdownComponent
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
