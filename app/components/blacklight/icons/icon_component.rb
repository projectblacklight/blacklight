# frozen_string_literal: true

module Blacklight
  module Icons
    # This is the list icon for the search button.
    # You can override the default svg by setting:
    #   Blacklight::Icons::ListComponent.svg = '<svg>your SVG here</svg>'
    class IconComponent < ::ViewComponent::Base
      def initialize(svg: nil)
        self.svg = svg if svg
      end

      def call
        svg&.html_safe # rubocop:disable Rails/OutputSafety
      end

      class_attribute :svg
    end
  end
end
