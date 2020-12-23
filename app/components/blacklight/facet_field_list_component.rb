# frozen_string_literal: true

module Blacklight
  class FacetFieldListComponent < ::ViewComponent::Base
    # @param [Blacklight::FacetFieldPresenter] facet_field
    # @param [Boolean] layout
    def initialize(facet_field:, layout: true)
      @presenter = facet_field
      @layout = layout == false ? FacetFieldNoLayoutComponent : Blacklight::FacetFieldComponent
    end

    ##
    # Renders the list of values
    # removes any elements where render_facet_item returns a nil value. This enables an application
    # to filter undesireable facet items so they don't appear in the UI
    def render_facet_limit_list
      collection = @presenter.paginator.items.map do |item|
        facet_item_presenter(item)
      end

      render(facet_item_component_class.with_collection(collection, wrapping_element: :li))
    end

    def render?
      @presenter.paginator.items.any?
    end

    def facet_item_presenter(facet_item)
      Blacklight::FacetItemPresenter.new(facet_item, @presenter.facet_field, helpers, @presenter.key)
    end

    def facet_item_component_class
      default_component = @presenter.facet_field.pivot ? Blacklight::FacetItemPivotComponent : Blacklight::FacetItemComponent
      @presenter.facet_field.fetch(:item_component, default_component)
    end
  end
end
