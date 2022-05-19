# frozen_string_literal: true

module Blacklight
  module Icons
    class LegacyIconComponent < ::ViewComponent::Base
      extend Deprecation

      def initialize(name:, classes: '', aria_hidden: false, label: true, role: 'img', additional_options: {})
        @name = name
        Deprecation.warn(self, "Calling the LegacyIconComponent with \"#{name}\" is deprecated. Instead create a component for this icon.")
        @classes = classes
        @aria_hidden = aria_hidden
        @icon = Blacklight::Icon.new(name, classes: classes, label: label, role: role, additional_options: additional_options)
      end

      def call
        tag.span(svg.html_safe,  # rubocop:disable Rails/OutputSafety
                 class: "blacklight-icons blacklight-icon-#{@name} #{@classes}".strip,
                 'aria-hidden': (true if @aria_hidden))
      end

      def svg
        Rails.cache.fetch([:blacklight_icon_svg, @name]) do
          @icon.svg
        end
      end
    end
  end
end
