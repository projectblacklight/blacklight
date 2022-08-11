# frozen_string_literal: true

module Blacklight
  class FacetFieldListComponent < Blacklight::Component
    def initialize(facet_field:, layout: nil)
      @facet_field = facet_field
      @layout = layout == false ? FacetFieldNoLayoutComponent : Blacklight::FacetFieldComponent
    end

    ##
    # Renders the list of values
    # removes any elements where render_facet_item returns a nil value. This enables an application
    # to filter undesireable facet items so they don't appear in the UI
    # @deprecated
    def render_facet_limit_list(paginator, facet_field, wrapping_element = :li)
      return render(facet_items(wrapping_element: wrapping_element)) if paginator == @facet_field.paginator && facet_field == @facet_field.key

      facet_config ||= helpers.facet_configuration_for_field(facet_field)

      collection = paginator.items.map do |item|
        facet_item_presenter(item, facet_config, facet_field)
      end

      render(facet_item_component_class(facet_config).with_collection(collection, wrapping_element: wrapping_element))
    end
    Blacklight.deprecation.deprecate_methods(self, render_facet_limit_list: 'Call e.g. `render facet_items` instead')

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
