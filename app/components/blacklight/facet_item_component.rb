# frozen_string_literal: true

module Blacklight
  class FacetItemComponent < Blacklight::Component
    attr_reader :label, :href, :hits

    with_collection_parameter :facet_item

    def initialize(facet_item:, wrapping_element: 'li', suppress_link: false)
      @facet_item = facet_item
      @label = facet_item.label
      @hits = facet_item.hits
      @href = facet_item.href
      @selected = facet_item.selected?
      @wrapping_element = wrapping_element
      @suppress_link = suppress_link
    end

    def call
      # if the downstream app has overridden the helper methods we'd usually call,
      # use the helpers to preserve compatibility
      content = if @selected
                  render_selected_facet_value
                else
                  render_facet_value
                end

      return '' if content.blank?
      return content unless @wrapping_element

      content_tag @wrapping_element, content
    end

    ##
    # Standard display of a facet value in a list. Used in both _facets sidebar
    # partial and catalog/facet expanded list. Will output facet value name as
    # a link to add that to your restrictions, with count in parens.
    #
    # @return [String]
    # @private
    def render_facet_value
      tag.span(class: "facet-label") do
        link_to_unless(@suppress_link, label, href, class: "facet-select", rel: "nofollow")
      end + render_facet_count
    end

    ##
    # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
    # @see #render_facet_value
    #
    # @private
    def render_selected_facet_value
      tag.span(class: "facet-label") do
        tag.span(label, class: "selected") +
          # remove link
          link_to(href, class: "remove", rel: "nofollow") do
            render(Blacklight::Icons::RemoveComponent.new) +
              tag.span(helpers.t(:'blacklight.search.facets.selected.remove'), class: 'sr-only visually-hidden')
          end
      end + render_facet_count(classes: ["selected"])
    end

    ##
    # Renders a count value for facet limits. Can be over-ridden locally
    # to change style. And can be called by plugins to get consistent display.
    #
    # @param [Hash] options
    # @option options [Array<String>]  an array of classes to add to count span.
    # @return [String]
    # @private
    def render_facet_count(options = {})
      return '' if hits.blank?

      classes = (options[:classes] || []) << "facet-count"
      tag.span(t('blacklight.search.facets.count', number: number_with_delimiter(hits)), class: classes)
    end
  end
end
