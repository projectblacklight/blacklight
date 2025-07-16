# frozen_string_literal: true

module Blacklight
  module Facets
    class ListComponent < Blacklight::Component
      # @param [Blacklight::FacetFieldPresenter] facet_field
      def initialize(facet_field:,
                     classes: %w[facet-values list-unstyled],
                     role: nil,
                     layout: nil)
        @facet_field = facet_field
        @classes = classes
        @role = role
        @layout = layout == false ? Blacklight::Facets::NoLayoutComponent : Blacklight::Facets::FieldComponent
      end

      attr_accessor :layout, :classes, :role

      def facet_items(wrapping_element: :li, **item_args)
        facet_item_component_class.with_collection(facet_item_presenters, wrapping_element: wrapping_element, **item_args)
      end

      def facet_item_presenters
        @facet_field.paginator.items.map do |item|
          facet_item_presenter(item)
        end
      end

      def render?
        @facet_field.paginator&.items&.any?
      end

      def facet_item_presenter(facet_item)
        @facet_field.item_presenter(facet_item)
      end

      def facet_item_component_class
        facet_config.item_component
      end

      def facet_config
        @facet_field.facet_field
      end
    end
  end
end
