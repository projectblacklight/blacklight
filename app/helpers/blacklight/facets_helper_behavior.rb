module Blacklight::FacetsHelperBehavior

  include Blacklight::Facet

  ##
  # Check if any of the given fields have values
  #
  # @param [Array<String>]
  # @param [Hash] options
  # @return [Boolean]
  def has_facet_values? fields = facet_field_names, options = {}
    facets_from_request(fields).any? { |display_facet| !display_facet.items.empty? }
  end

  ##
  # Render a collection of facet fields.
  # @see #render_facet_limit 
  # 
  # @param [Array<String>]
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
  # @param [Blacklight::SolrResponse::Facets::FacetField] display_facet 
  # @param [Hash] options parameters to use for rendering the facet limit partial
  # @option options [String] :partial partial to render
  # @option options [String] :layout partial layout to render
  # @option options [Hash] :locals locals to pass to the partial
  # @return [String] 
  def render_facet_limit(display_facet, options = {})
    return if not should_render_facet?(display_facet)
    options = options.dup
    options[:partial] ||= facet_partial_name(display_facet)
    options[:layout] ||= "facet_layout" unless options.has_key?(:layout)
    options[:locals] ||= {}
    options[:locals][:solr_field] ||= display_facet.name 
    options[:locals][:facet_field] ||= facet_configuration_for_field(display_facet.name)
    options[:locals][:display_facet] ||= display_facet 

    render(options)
  end

  ##
  # Determine if Blacklight should render the display_facet or not
  #
  # By default, only render facets with items.
  #
  # @param [Blacklight::SolrResponse::Facets::FacetField] display_facet
  # @return [Boolean] 
  def should_render_facet? display_facet
    # display when show is nil or true
    facet_config = facet_configuration_for_field(display_facet.name)

    display = case facet_config.show
    when Symbol
      arity = method(facet_config.show).arity

      if arity == 0
        send(facet_config.show)
      else 
        send(facet_config.show, display_facet)
      end
    when Proc
      facet_config.show.call self, facet_config, display_facet
    else
      facet_config.show
    end

    return display && display_facet.items.present?
  end

  ##
  # Determine whether a facet should be rendered as collapsed or not.
  #   - if the facet is 'active', don't collapse
  #   - if the facet is configured to collapse (the default), collapse
  #   - if the facet is configured not to collapse, don't collapse
  # 
  # @param [Blacklight::Configuration::FacetField]
  # @return [Boolean]
  def should_collapse_facet? facet_field
    !facet_field_in_params?(facet_field.field) && facet_field.collapse
  end

  ##
  # the name of the partial to use to render a facet field.
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
  # @param [Blacklight::SolrResponse::Facets::FacetField]
  # @param [String] facet item
  # @param [Hash] options
  # @option options [Boolean] :suppress_link display the facet, but don't link to it
  # @option options [Rails::Engine] :route_set route set to use to render the link
  # @return [String]
  def render_facet_value(facet_solr_field, item, options ={})    
    scope = options.delete(:route_set) || self
    path = scope.url_for(add_facet_params_and_redirect(facet_solr_field, item).merge(only_path: true))
    content_tag(:span, :class => "facet-label") do
      link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item), path, :class=>"facet_select")
    end + render_facet_count(item.hits)
  end

  ##
  # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
  # @params (see #render_facet_value)
  def render_selected_facet_value(facet_solr_field, item)
    content_tag(:span, :class => "facet-label") do
      content_tag(:span, facet_display_value(facet_solr_field, item), :class => "selected") +
      # remove link
      link_to(content_tag(:span, '', :class => "glyphicon glyphicon-remove") + content_tag(:span, '[remove]', :class => 'sr-only'), remove_facet_params(facet_solr_field, item, params), :class=>"remove")
    end + render_facet_count(item.hits, :classes => ["selected"])
  end

  ##
  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display. 
  #
  # @param [Integer] number of facet results
  # @param [Hash] options
  # @option options [Array<String>]  an array of classes to add to count span.
  # @return [String]
  def render_facet_count(num, options = {})
    classes = (options[:classes] || []) << "facet-count"
    content_tag("span", t('blacklight.search.facets.count', :number => num), :class => classes)
  end
  
  ##
  # Are any facet restrictions for a field in the query parameters?
  # 
  # @param [String] facet field
  # @return [Boolean]
  def facet_field_in_params? field
    params[:f] and params[:f][field]
  end
  
  ##
  # Check if the query parameters have the given facet field with the 
  # given value.
  # 
  # @param [Object] facet field
  # @param [Object] facet value
  # @return [Boolean]
  def facet_in_params?(field, item)
    if item and item.respond_to? :field
      field = item.field
    end

    value = facet_value_for_facet_item(item)

    facet_field_in_params?(field) and params[:f][field].include?(value)
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
      value = item.label
    else
      facet_value_for_facet_item(item)
    end

    display_label = case
      when facet_config.helper_method
        display_label = send facet_config.helper_method, value 
      when (facet_config.query and facet_config.query[value])
        display_label = facet_config.query[value][:label]     
      when facet_config.date
        localization_options = {}
        localization_options = facet_config.date unless facet_config.date === true
        display_label = l(value.to_datetime, localization_options)
      else
        value
    end
  end


  private

  def facet_value_for_facet_item item
    if item.respond_to? :value
      value = item.value
    else
      value = item
    end
  end

end
