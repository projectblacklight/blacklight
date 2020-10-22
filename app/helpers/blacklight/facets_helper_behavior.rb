# frozen_string_literal: true
module Blacklight::FacetsHelperBehavior
  extend Deprecation
  self.deprecation_horizon = 'blacklight 8.0'

  include Blacklight::Facet

  ##
  # Check if any of the given fields have values
  #
  # @deprecated
  # @param [Array<String>] fields
  # @return [Boolean]
  def has_facet_values? fields = facet_field_names, response = nil
    deprecated_method(:has_facet_values?)
    unless response
      Deprecation.warn(self, 'Calling has_facet_values? without passing the ' \
        'second argument (response) is deprecated and will be removed in Blacklight ' \
        '8.0.0')
      response = @response
    end
    Deprecation.silence(Blacklight::FacetsHelperBehavior) do
      Deprecation.silence(Blacklight::Facet) do
        facets_from_request(fields, response).any? { |display_facet| should_render_facet?(display_facet) }
      end
    end
  end

  ##
  # Render a collection of facet fields.
  # @see #render_facet_limit
  #
  # @deprecated
  # @param [Array<String>] fields
  # @param [Hash] options
  # @option options [Blacklight::Solr::Response] :response the Solr response object
  # @return String
  def render_facet_partials fields = nil, options = {}
    deprecated_method(:render_facet_partials)

    unless fields
      Deprecation.warn(self.class, 'Calling render_facet_partials without passing the ' \
        'first argument (fields) is deprecated and will be removed in Blacklight ' \
        '8.0.0')
      fields = facet_field_names
    end

    response = options.delete(:response)
    unless response
      Deprecation.warn(self.class, 'Calling render_facet_partials without passing the ' \
        'response keyword is deprecated and will be removed in Blacklight ' \
        '8.0.0')
      response = @response
    end
    Deprecation.silence(Blacklight::FacetsHelperBehavior) do
      Deprecation.silence(Blacklight::Facet) do
        safe_join(facets_from_request(fields, response).map do |display_facet|
          render_facet_limit(display_facet, options)
        end.compact, "\n")
      end
    end
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
    field_config = facet_configuration_for_field(display_facet.name)

    if field_config.component
      return unless should_render_field?(field_config, display_facet)

      component = field_config.component == true ? Blacklight::FacetFieldListComponent : field_config.component

      return render(
        component.new(
          facet_field: facet_field_presenter(field_config, display_facet),
          layout: (params[:action] == 'facet' ? false : options[:layout])
        )
      )
    end

    Deprecation.warn(Blacklight::FacetsHelperBehavior, 'Calling #render_facet_limit on a non-componentized'\
      ' facet is deprecated and will be removed in Blacklight 8')

    Deprecation.silence(Blacklight::FacetsHelperBehavior) do
      return unless should_render_facet?(display_facet, field_config)
    end
    options = options.dup

    Deprecation.silence(Blacklight::FacetsHelperBehavior) do
      options[:partial] ||= facet_partial_name(display_facet)
    end

    options[:layout] ||= "facet_layout" unless options.key?(:layout)
    options[:locals] ||= {}
    options[:locals][:field_name] ||= display_facet.name
    options[:locals][:facet_field] ||= field_config
    options[:locals][:display_facet] ||= display_facet

    render(options)
  end

  ##
  # Renders the list of values
  # removes any elements where render_facet_item returns a nil value. This enables an application
  # to filter undesireable facet items so they don't appear in the UI
  # @deprecated
  def render_facet_limit_list(paginator, facet_field, wrapping_element = :li)
    facet_config ||= facet_configuration_for_field(facet_field)

    collection = paginator.items.map do |item|
      facet_item_presenter(facet_config, item, facet_field)
    end

    render(facet_item_component_class(facet_config).with_collection(collection, wrapping_element: wrapping_element))
  end
  deprecation_deprecate :render_facet_limit_list

  ##
  # Renders a single facet item
  # @deprecated
  def render_facet_item(facet_field, item)
    deprecated_method(:render_facet_item)
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
  # @deprecated
  # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
  # @param [Blacklight::Configuration::FacetField] facet_config
  # @return [Boolean]
  def should_render_facet? display_facet, facet_config = nil
    return false if display_facet.items.blank?

    # display when show is nil or true
    facet_config ||= facet_configuration_for_field(display_facet.name)
    should_render_field?(facet_config, display_facet)
  end
  deprecation_deprecate :should_render_facet?

  ##
  # Determine whether a facet should be rendered as collapsed or not.
  #   - if the facet is 'active', don't collapse
  #   - if the facet is configured to collapse (the default), collapse
  #   - if the facet is configured not to collapse, don't collapse
  #
  # @deprecated
  # @param [Blacklight::Configuration::FacetField] facet_field
  # @return [Boolean]
  def should_collapse_facet? facet_field
    Deprecation.silence(Blacklight::FacetsHelperBehavior) do
      !facet_field_in_params?(facet_field.key) && facet_field.collapse
    end
  end
  deprecation_deprecate :should_collapse_facet?

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
    name || "facet_limit"
  end
  deprecation_deprecate :facet_partial_name

  def facet_field_presenter(facet_config, display_facet)
    (facet_config.presenter || Blacklight::FacetFieldPresenter).new(facet_config, display_facet, self)
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
    deprecated_method(:render_facet_value)
    facet_config = facet_configuration_for_field(facet_field)
    facet_item_component(facet_config, item, facet_field, **options).render_facet_value
  end

  ##
  # Where should this facet link to?
  #
  # @deprecated
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  # @return [String]
  def path_for_facet(facet_field, item, path_options = {})
    facet_config = facet_configuration_for_field(facet_field)
    facet_item_presenter(facet_config, item, facet_field).href(path_options)
  end
  deprecation_deprecate :path_for_facet

  ##
  # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
  #
  # @deprecated
  # @see #render_facet_value
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  def render_selected_facet_value(facet_field, item)
    deprecated_method(:render_selected_facet_value)
    facet_config = facet_configuration_for_field(facet_field)
    facet_item_component(facet_config, item, facet_field).render_selected_facet_value
  end

  ##
  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display.
  #
  # @deprecated
  # @param [Integer] num number of facet results
  # @param [Hash] options
  # @option options [Array<String>]  an array of classes to add to count span.
  # @return [String]
  def render_facet_count(num, options = {})
    deprecated_method(:render_facet_count)
    classes = (options[:classes] || []) << "facet-count"
    tag.span(t('blacklight.search.facets.count', number: number_with_delimiter(num)), class: classes)
  end

  ##
  # Are any facet restrictions for a field in the query parameters?
  # @private
  # @param [String] field
  # @return [Boolean]
  def facet_field_in_params? field
    config = facet_configuration_for_field(field)

    Deprecation.silence(Blacklight::SearchState) do
      search_state.has_facet? config
    end
  end
  # Left undeprecated for the sake of temporary backwards compatibility
  # deprecation_deprecate :facet_field_in_params?

  ##
  # Check if the query parameters have the given facet field with the
  # given value.
  #
  # @deprecated
  # @param [String] field
  # @param [String] item facet value
  # @return [Boolean]
  def facet_in_params?(field, item)
    config = facet_configuration_for_field(field)

    Deprecation.silence(Blacklight::SearchState) do
      search_state.has_facet? config, value: facet_value_for_facet_item(item)
    end
  end
  deprecation_deprecate :facet_in_params?

  ##
  # Get the values of the facet set in the blacklight query string
  # @deprecated
  def facet_params field
    config = facet_configuration_for_field(field)

    search_state.params.dig(:f, config.key)
  end
  deprecation_deprecate :facet_params

  ##
  # Get the displayable version of a facet's value
  #
  # @param [Object] field
  # @param [String] item value
  # @return [String]
  # @deprecated
  def facet_display_value field, item
    deprecated_method(:facet_display_value)
    facet_config = facet_configuration_for_field(field)
    facet_item_presenter(facet_config, item, field).label
  end

  # @deprecated
  def facet_field_id facet_field
    "facet-#{facet_field.key.parameterize}"
  end
  deprecation_deprecate :facet_field_id

  private

  def facet_value_for_facet_item item
    if item.respond_to? :value
      item.value
    else
      item
    end
  end

  def facet_item_presenter(facet_config, facet_item, facet_field)
    Blacklight::FacetItemPresenter.new(facet_item, facet_config, self, facet_field)
  end

  def facet_item_component(facet_config, facet_item, facet_field, **args)
    facet_item_component_class(facet_config).new(facet_item: facet_item_presenter(facet_config, facet_item, facet_field), **args).with_view_context(self)
  end

  def facet_item_component_class(facet_config)
    default_component = facet_config.pivot ? Blacklight::FacetItemPivotComponent : Blacklight::FacetItemComponent
    facet_config.fetch(:item_component, default_component)
  end

  # We can't use .deprecation_deprecate here, because the new components need to
  # see the originally defined location for these methods in order to properly
  # call back into the helpers for backwards compatibility
  def deprecated_method(method_name)
    Deprecation.warn(Blacklight::FacetsHelperBehavior,
                     Deprecation.deprecated_method_warning(Blacklight::FacetsHelperBehavior,
                                                           method_name, {}),
                     caller)
  end
end
