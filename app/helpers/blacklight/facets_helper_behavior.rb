# frozen_string_literal: true
module Blacklight::FacetsHelperBehavior
  include Blacklight::Facet

  ##
  # Check if any of the given fields have values
  #
  # @param [Array<String>] fields
  # @return [Boolean]
  def has_facet_values? fields = facet_field_names
    facets_from_request(fields).any? { |display_facet| !display_facet.items.empty? && should_render_facet?(display_facet) }
  end

  ##
  # Render a collection of facet fields.
  # @see #render_facet_limit
  #
  # @param [Array<String>] fields
  # @param [Hash] options
  # @return String
  def render_facet_partials fields = facet_field_names, options = {}
    safe_join(facets_from_request(fields).map do |display_facet|
      render_facet_limit(display_facet, options)
    end.compact, "\n")
  end

  ##
  # Renders a single section for facet limit with a specified
  # solr field used for faceting. Can be over-ridden for custom
  # display on a per-facet basis.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
  # @param [Hash] options parameters to use for rendering the facet limit partial
  # @option options [String] :partial partial to render
  # @option options [String] :layout partial layout to render
  # @option options [Hash] :locals locals to pass to the partial
  # @return [String]
  def render_facet_limit(display_facet, options = {})
    return unless should_render_facet?(display_facet)
    options = options.dup
    options[:partial] ||= facet_partial_name(display_facet)
    options[:layout] ||= "facet_layout" unless options.key?(:layout)
    options[:locals] ||= {}
    options[:locals][:field_name] ||= display_facet.name
    options[:locals][:facet_field] ||= facet_configuration_for_field(display_facet.name)
    options[:locals][:display_facet] ||= display_facet

    render(options)
  end

  ##
  # Renders the list of values
  # removes any elements where render_facet_item returns a nil value. This enables an application
  # to filter undesireable facet items so they don't appear in the UI
  def render_facet_limit_list(paginator, facet_field, wrapping_element = :li)
    safe_join(paginator.items.map { |item| render_facet_item(facet_field, item) }.compact.map { |item| content_tag(wrapping_element, item) })
  end

  ##
  # Renders a single facet item
  def render_facet_item(facet_field, item)
    if facet_in_params?(facet_field, item.value)
      render_selected_facet_value(facet_field, item)
    else
      render_facet_value(facet_field, item)
    end
  end

  ##
  # Determine if Blacklight should render the display_facet or not
  #
  # By default, only render facets with items.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
  # @return [Boolean]
  def should_render_facet? display_facet
    # display when show is nil or true
    facet_config = facet_configuration_for_field(display_facet.name)
    display = should_render_field?(facet_config, display_facet)
    display && display_facet.items.present?
  end

  ##
  # Determine whether a facet should be rendered as collapsed or not.
  #   - if the facet is 'active', don't collapse
  #   - if the facet is configured to collapse (the default), collapse
  #   - if the facet is configured not to collapse, don't collapse
  #
  # @param [Blacklight::Configuration::FacetField] facet_field
  # @return [Boolean]
  def should_collapse_facet? facet_field
    !facet_field_in_params?(facet_field.key) && facet_field.collapse
  end

  ##
  # The name of the partial to use to render a facet field.
  # uses the value of the "partial" field if set in the facet configuration
  # otherwise uses "facet_pivot" if this facet is a pivot facet
  # defaults to 'facet_limit'
  #
  # @return [String]
  def facet_partial_name(display_facet = nil)
    config = facet_configuration_for_field(display_facet.name)
    name = config.try(:partial)
    name ||= "facet_pivot" if config.pivot
    name ||= "facet_limit"
  end

  ##
  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem] item
  # @param [Hash] options
  # @option options [Boolean] :suppress_link display the facet, but don't link to it
  # @return [String]
  def render_facet_value(facet_field, item, options = {})
    path = path_for_facet(facet_field, item)
    content_tag(:span, class: "facet-label") do
      link_to_unless(options[:suppress_link],
                     facet_display_value(facet_field, item),
                     path,
                     class: "facet-select")
    end + render_facet_count(item.hits)
  end

  ##
  # Where should this facet link to?
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  # @return [String]
  def path_for_facet(facet_field, item)
    facet_config = facet_configuration_for_field(facet_field)
    if facet_config.url_method
      send(facet_config.url_method, facet_field, item)
    else
      search_action_path(search_state.add_facet_params_and_redirect(facet_field, item))
    end
  end

  ##
  # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
  # @see #render_facet_value
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  def render_selected_facet_value(facet_field, item)
    remove_href = search_action_path(search_state.remove_facet_params(facet_field, item))
    content_tag(:span, class: "facet-label") do
      content_tag(:span, facet_display_value(facet_field, item), class: "selected") +
      # remove link
      link_to(remove_href, class: "remove") do
        content_tag(:span, '✖', class: "remove-icon") +
        content_tag(:span, '[remove]', class: 'sr-only')
      end
    end + render_facet_count(item.hits, classes: ["selected"])
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

  ##
  # Are any facet restrictions for a field in the query parameters?
  #
  # @param [String] field
  # @return [Boolean]
  def facet_field_in_params? field
    !facet_params(field).blank?
  end

  ##
  # Check if the query parameters have the given facet field with the
  # given value.
  #
  # @param [Object] field
  # @param [Object] item facet value
  # @return [Boolean]
  def facet_in_params?(field, item)
    value = facet_value_for_facet_item(item)

    (facet_params(field) || []).include? value
  end

  ##
  # Get the values of the facet set in the blacklight query string
  def facet_params field
    config = facet_configuration_for_field(field)

    params[:f][config.key] if params[:f]
  end

  ##
  # Get the displayable version of a facet's value
  #
  # @param [Object] field
  # @param [String] item value
  # @return [String]
  def facet_display_value field, item
    facet_config = facet_configuration_for_field(field)

    value = if item.respond_to? :label
              item.label
            else
              facet_value_for_facet_item(item)
            end

    if facet_config.helper_method
      send facet_config.helper_method, value
    elsif facet_config.query && facet_config.query[value]
      facet_config.query[value][:label]
    elsif facet_config.date
      localization_options = facet_config.date == true ? {} : facet_config.date

      l(value.to_datetime, localization_options)
    else
      value
    end
  end

  def facet_field_id facet_field
    "facet-#{facet_field.key.parameterize}"
  end

  private

  def facet_value_for_facet_item item
    if item.respond_to? :value
      item.value
    else
      item
    end
  end
end
