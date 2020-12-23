# frozen_string_literal: true

module Blacklight
  class FacetFieldListComponent < ::ViewComponent::Base
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
      facet_config ||= helpers.facet_configuration_for_field(facet_field)

      collection = paginator.items.map do |item|
        facet_item_presenter(item, facet_config, facet_field)
      end

      render(facet_item_component_class(facet_config).with_collection(collection, wrapping_element: wrapping_element))
    end

    def render?
      @facet_field.paginator.items.any?
    end

    def facet_item_presenter(facet_item, facet_config, facet_field)
      Blacklight::FacetItemPresenter.new(facet_item, facet_config, helpers, facet_field)
    end

    def facet_item_component_class(facet_config)
      default_component = facet_config.pivot ? Blacklight::FacetItemPivotComponent : Blacklight::FacetItemComponent
      facet_config.fetch(:item_component, default_component)
    end
  end
end
