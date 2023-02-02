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
    end
  end
end
