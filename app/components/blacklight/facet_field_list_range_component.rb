# frozen_string_literal: true

module Blacklight
  class FacetFieldListRangeComponent < Blacklight::Component
    # @param [Blacklight::FacetFieldRangePresenter] facet_field
    def initialize(facet_field:, layout: nil)
      @facet_field = facet_field
      @layout = layout == false ? FacetFieldNoLayoutComponent : Blacklight::FacetFieldComponent
    end

    def facet_items(wrapping_element: :li, **item_args)
      facet_item_component_class.with_collection(facet_item_presenters, wrapping_element: wrapping_element, **item_args)
    end

    def facet_item_presenters
      @facet_field.paginator.items.map do |item|
        facet_item_presenter(item)
      end
    end

    def facet_item_presenter(facet_item, deprecated_facet_config = nil, facet_field = nil)
      (deprecated_facet_config || facet_config).item_presenter.new(facet_item, deprecated_facet_config || facet_config, helpers, facet_field || @facet_field.key)
    end

    def facet_item_component_class(deprecated_facet_config = nil)
      (deprecated_facet_config || facet_config).item_component
    end

    def facet_config
      @facet_field.facet_field
    end
  end
end
