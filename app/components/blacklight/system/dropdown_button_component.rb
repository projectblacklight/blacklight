# frozen_string_literal: true

module Blacklight
  module System
    class DropdownButtonComponent < Blacklight::Component
      def initialize(label:, classes: %w[btn btn-outline-secondary dropdown-toggle])
        @classes = classes
        @label = label
      end

      def call
        button_tag class: @classes, aria: { expanded: false }, data: { toggle: 'dropdown', 'bs-toggle': 'dropdown' } do
          safe_join([@label, content_tag(:span, '', class: 'caret')])
        end
      end
    end
  end
end
