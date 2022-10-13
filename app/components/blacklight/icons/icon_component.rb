# frozen_string_literal: true

module Blacklight
  module Icons
    # This is the list icon for the search button.
    # You can override the default svg by setting:
    #   Blacklight::Icons::ListComponent.svg = '<svg>your SVG here</svg>'
    class IconComponent < ::ViewComponent::Base
      # rubocop:disable Metrics/ParameterLists
      def initialize(svg: nil, tag: :span, name: nil, label: nil, aria_hidden: nil, classes: nil, **options)
        self.svg = svg if svg
        @classes = Array(classes) + ['blacklight-icons', "blacklight-icons-#{name}"]
        @name = name
        @tag = tag
        @options = options.merge(aria: options.fetch(:aria, {}).reverse_merge(label: label, hidden: aria_hidden))
      end
      # rubocop:enable Metrics/ParameterLists

      def call
        tag.public_send(@tag, svg&.html_safe, # rubocop:disable Rails/OutputSafety
                        class: @classes,
                        **@options)
      end

      class_attribute :svg

      def name
        @name ||= self.class.name.demodulize.underscore.sub('_component', '')
      end
    end
  end
end
