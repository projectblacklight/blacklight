# frozen_string_literal: true

module Blacklight
  class FacetItemPresenter
    class_attribute :facet_value_presenter
    self.facet_value_presenter = FacetValuePresenter

    # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
    # @param [Blacklight::Solr::Response::Facets::FacetItem] item
    def initialize(facet_field, item, view_context)
      @facet_field = facet_field
      @item = item
      @view_context = view_context
    end

    attr_reader :facet_field, :item, :view_context

    delegate :facet_configuration_for_field, :content_tag, :l, :number_with_delimiter,
             :link_to, :link_to_unless, :search_state, :search_action_path, :t, to: :view_context

    ##
    # Renders a single facet item
    def render_item
      if view_context.facet_in_params?(facet_field, item)
        selected_facet_value
      else
        facet_value
      end
    end

    def as_json
      {
        'attributes' => {
          'label' => item.label,
          'value' => item.value,
          'hits' => item.hits
        },
        'links' => {
          'self' => path_for_facet(facet_field.name, item.value, only_path: false)
        }
      }
    end

    ##
    # Standard display of a facet value in a list. Used in both _facets sidebar
    # partial and catalog/facet expanded list. Will output facet value name as
    # a link to add that to your restrictions, with count in parens.
    #
    # @param [Hash] options
    # @option options [Boolean] :suppress_link display the facet, but don't link to it
    # @return [String]
    def facet_value(options = {})
      path = path_for_facet(facet_field, item)
      content_tag(:span, class: "facet-label") do
        link_to_unless(options[:suppress_link],
                       facet_display_value,
                       path,
                       class: "facet-select")
      end + render_facet_count(item.hits)
    end

    private

    ##
    # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
    # @see #render_facet_value
    # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
    # @param [String] item
    def selected_facet_value
      remove_href = search_action_path(search_state.remove_facet_params(facet_field, item))
      content_tag(:span, class: "facet-label") do
        content_tag(:span, facet_display_value, class: "selected") +
          # remove link
          link_to(remove_href, class: "remove") do
            content_tag(:span, '✖', class: "remove-icon") +
              content_tag(:span, '[remove]', class: 'sr-only')
          end
      end + render_facet_count(item.hits, classes: ["selected"])
    end

    def facet_display_value
      facet_value_presenter.new(facet_field, item, view_context).display
    end

    ##
    # Where should this facet link to?
    # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
    # @param [String] item
    # @param [Hash] path_options
    # @return [String]
    def path_for_facet(facet_field, item, path_options = {})
      facet_config = facet_configuration_for_field(facet_field)
      if facet_config.url_method
        view_context.send(facet_config.url_method, facet_field, item)
      else
        search_action_path(search_state.add_facet_params_and_redirect(facet_field, item).merge(path_options))
      end
    end

    ##
    # Renders a count value for facet limits. Can be over-ridden locally
    # to change style. And can be called by plugins to get consistent display.
    #
    # @param [Integer] num number of facet results
    # @param [Hash] options
    # @option options [Array<String>]  an array of classes to add to count span.
    # @return [String]
    def render_facet_count(num, options = {})
      classes = (options[:classes] || []) << "facet-count"
      content_tag("span", t('blacklight.search.facets.count', number: number_with_delimiter(num)), class: classes)
    end
  end
end
