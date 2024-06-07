# frozen_string_literal: true

module Blacklight
  # Render facet items and any subtree
  class FacetItemPivotComponent < Blacklight::Component
    # Somewhat arbitrary number; the only important thing is that
    # it is bigger than the number of leaf nodes in any collapsing
    # pivot facet on the page.
    ID_COUNTER_MAX = (2**20) - 1

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
      @icons = { show: tag.span(class: 'icon'), hide: tag.span(class: 'icon') }.merge(facet_item.facet_config.icons || {})
    end

    def call
      facet = Blacklight::FacetItemComponent.new(facet_item: @facet_item, wrapping_element: nil, suppress_link: @suppress_link)

      id = "h-#{self.class.mint_id}" if @collapsing && has_items?

      content_tag @wrapping_element, role: 'treeitem', class: 'treeitem' do
        concat(content_tag('span', class: "d-flex flex-row align-items-center") do
          concat facet_toggle_button(id) if has_items? && @collapsing
          concat content_tag('span', render(facet), class: "facet-values d-flex flex-row flex-grow-1 #{'facet-leaf-node' if has_items? && @collapsing}", id: id && "#{id}_label")
        end)
        if has_items?
          concat(content_tag('ul', class: "pivot-facet flex-column list-unstyled ps-4 #{'collapse' if @collapsing} #{'show' if expanded?}", id: id, role: 'group') do
            render(
              self.class.with_collection(
                @facet_item.facet_item_presenters.to_a
              )
            )
          end)
        end
      end
    end

    private

    def has_items?
      return false unless @facet_item.respond_to? :facet_item_presenters

      @facet_item.facet_item_presenters.any?
    end

    def expanded?
      return false unless @collapsing

      @facet_item.shown?
    end

    def facet_toggle_button(id)
      content_tag 'button', class: %w[btn facet-toggle-handle] + [('collapsed' unless expanded?)],
                            data: { toggle: 'collapse', 'bs-toggle': 'collapse', target: "##{id}", 'bs-target': "##{id}" },
                            aria: { expanded: expanded?, controls: id, describedby: "#{id}_label" } do
        concat toggle_icon(:show)
        concat toggle_icon(:hide)
      end
    end

    def toggle_icon(type)
      content_tag 'span', class: type do
        concat @icons[type]
        concat content_tag('span', t(type, scope: 'blacklight.search.facets.pivot'), class: 'sr-only visually-hidden')
      end
    end
  end
end
