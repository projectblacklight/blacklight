# frozen_string_literal: true

module Blacklight
  # Render facet items and any subtree
  class FacetItemPivotComponent < ::ViewComponent::Base
    with_collection_parameter :facet_item

    def initialize(facet_item:, wrapping_element: 'li', suppress_link: false)
      @facet_item = facet_item
      @wrapping_element = wrapping_element
      @suppress_link = suppress_link
    end

    def call
      facet = Blacklight::FacetItemComponent.new(facet_item: @facet_item, wrapping_element: nil, suppress_link: @suppress_link)

      content_tag @wrapping_element do
        concat content_tag('span', render_component(facet), class: 'facet-values')

        if @facet_item.items.present?
          concat(content_tag('ul', class: 'pivot-facet list-unstyled') do
            render_component(
              self.class.with_collection(
                @facet_item.items.map { |i| facet_item_presenter(i) }
              )
            )
          end)
        end
      end
    end

    private

    # This is a little convoluted in Blacklight 7 in order to maintain backwards-compat
    # with overrides of deprecated helpers. In 8.x, we can just call Component#render_in
    # and call it a day
    def render_component(component)
      @view_context.render(component)
    end

    def facet_item_presenter(facet_item)
      Blacklight::FacetItemPresenter.new(facet_item, @facet_item.facet_config, @view_context, @facet_item.facet_field, @facet_item.search_state)
    end
  end
end
