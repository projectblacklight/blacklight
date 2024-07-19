# frozen_string_literal: true

module Blacklight
  module Icons
    # This is the base class for icon components. You should extend this class for each icon.
    #
    # You can override the default svg by setting:
    #   Blacklight::Icons::MyIconComponent.svg = '<svg>your SVG here</svg>'
    class IconComponent < ::ViewComponent::Base
      # rubocop:disable Metrics/ParameterLists
      def initialize(svg: nil, tag: :span, name: nil, label: nil, aria_hidden: nil, classes: nil, **options)
        self.svg = svg if svg
        @name = name
        @assigned_classes = Array(classes)
        @tag = tag
        @options = options.merge(aria: options.fetch(:aria, {}).reverse_merge(label: label, hidden: aria_hidden))
      end
      # rubocop:enable Metrics/ParameterLists

      def call
        tag.public_send(@tag, svg&.html_safe, # rubocop:disable Rails/OutputSafety
                        class: classes,
                        **@options)
      end

      class_attribute :svg

      def classes
        @classes ||= @assigned_classes + ['blacklight-icons', "blacklight-icons-#{name}"]
      end

      def name
        @name ||= self.class.name.demodulize.underscore.sub('_component', '')
      end
    end
  end
end
