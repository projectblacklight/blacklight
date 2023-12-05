# frozen_string_literal: true

module Blacklight
  module Icons
    class LegacyIconComponent < ::ViewComponent::Base
      def initialize(name:, classes: '', aria_hidden: false, label: true, role: 'img', additional_options: {})
        @name = name
        @classes = classes
        @aria_hidden = aria_hidden
        @icon = Blacklight::Icon.new(name, classes: classes, label: label, role: role, additional_options: additional_options)
      end

      def call
        tag.span(svg&.html_safe || default_icon, # rubocop:disable Rails/OutputSafety
                 class: "blacklight-icons blacklight-icon-#{@name} #{@classes}".strip,
                 'aria-hidden': (true if @aria_hidden))
      end

      def svg
        Rails.cache.fetch([:blacklight_icon_svg, @name]) do
          @icon.svg if @icon.present?
        end
      end

      def default_icon
        @icon.icon_label
      end
    end
  end
end
