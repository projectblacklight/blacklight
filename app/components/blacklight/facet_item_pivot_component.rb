# frozen_string_literal: true

module Blacklight
  # Render facet items and any subtree
  class FacetItemPivotComponent < ::ViewComponent::Base
    # Somewhat arbitrary number; the only important thing is that
    # it is bigger than the number of leaf nodes in any collapsing
    # pivot facet on the page.
    ID_COUNTER_MAX = 2**20 - 1

    # Mint a (sufficiently) unique identifier, so we can associate
    # the expand/collapse control with labels
    def self.mint_id
      @id_counter = ((@id_counter || 0) + 1) % ID_COUNTER_MAX

      # We convert the ID to hex for markup compactness
      @id_counter.to_s(16)
    end

    with_collection_parameter :facet_item

    def initialize(facet_item:, wrapping_element: 'li', suppress_link: false, collapsing: nil)
      @facet_item = facet_item
      @wrapping_element = wrapping_element
      @suppress_link = suppress_link
      @collapsing = collapsing.nil? ? facet_item.facet_config.collapsing : collapsing
      @icons = { show: '⊞', hide: '⊟' }.merge(facet_item.facet_config.icons || {})
    end

    def call
      facet = Blacklight::FacetItemComponent.new(facet_item: @facet_item, wrapping_element: nil, suppress_link: @suppress_link)

      id = "h-#{self.class.mint_id}" if @collapsing && has_items?

      content_tag @wrapping_element, role: 'treeitem' do
        concat facet_toggle_button(id) if has_items? && @collapsing
        concat content_tag('span', render_component(facet), class: "facet-values #{'facet-leaf-node' if has_items? && @collapsing}", id: id && "#{id}_label")

        if has_items?
          concat(content_tag('ul', class: "pivot-facet list-unstyled #{'collapse' if @collapsing}", id: id, role: 'group') do
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

    def has_items?
      @facet_item.items.present?
    end

    def facet_toggle_button(id)
      content_tag 'button', class: 'btn facet-toggle-handle collapsed',
                            data: { toggle: 'collapse', target: "##{id}" },
                            aria: { expanded: false, controls: id, describedby: "#{id}_label" } do
        concat toggle_icon(:show)
        concat toggle_icon(:hide)
      end
    end

    def toggle_icon(type)
      content_tag 'span', class: type do
        concat @icons[type]
        concat content_tag('span', t(type, scope: 'blacklight.search.facets.pivot'), class: 'sr-only')
      end
    end

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
