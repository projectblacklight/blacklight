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
    end
  end
end
