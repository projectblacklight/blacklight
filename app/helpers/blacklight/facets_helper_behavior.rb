module Blacklight::FacetsHelperBehavior

  #
  # blacklight_config based helpers ->
  #
  
  def facet_configuration_for_field(field)
    blacklight_config.facet_fields[field] || Blacklight::Configuration::FacetField.new(:field => field)
  end

  # used in the catalog/_facets partial
  def facet_field_labels
    # DEPRECATED
    Hash[*blacklight_config.facet_fields.map { |key, facet| [key, facet.label] }.flatten]
  end
  
  # used in the catalog/_facets partial
  def facet_field_names
    blacklight_config.facet_fields.keys
  end

  # Render a collection of facet fields
  def render_facet_partials fields = facet_field_names, options = {}
    solr_fields = fields.map { |solr_field| facet_by_field_name(solr_field) }.compact

    solr_fields.map do |display_facet|
      render_facet_limit(display_facet, options)
    end.compact.join("\n").html_safe
  end

  # Get a FacetField object from the @response
  def facet_by_field_name solr_field
    case solr_field
      when String, Symbol
        @response.facet_by_field_name(solr_field)
      when Blacklight::Configuration::FacetField
        @response.facet_by_field_name(solr_field.field)
      else
        solr_field
      end
  end

  # used in the catalog/_facets partial and elsewhere
  # Renders a single section for facet limit with a specified
  # solr field used for faceting. Can be over-ridden for custom
  # display on a per-facet basis. 
  #
  # @param [RSolr::Ext::Response::Facets::FacetField] display_facet 
  # @param [Hash] options parameters to use for rendering the facet limit partial
  #
  def render_facet_limit(display_facet, options = {})
    if display_facet.is_a? String or display_facet.is_a? Symbol
      $stderr.puts "DEPRECATION WARNING: Blacklight::FacetsHelper#render_facet_limit: use #render_facet_partials to render facets by field name"
      return render_facet_partials([display_facet])
    end
    return if not should_render_facet?(display_facet)
    options = options.dup
    options[:partial] ||= facet_partial_name(display_facet)
    options[:layout] ||= "facet_layout" unless options.has_key?(:layout)
    options[:locals] ||= {}
    options[:locals][:solr_field] ||= display_facet.name 
    options[:locals][:solr_fname] ||= display_facet.name # DEPRECATED
    options[:locals][:facet_field] ||= facet_configuration_for_field(display_facet.name)
    options[:locals][:display_facet] ||= display_facet 

    render(options)
  end

  ##
  # Determine if Blacklight should render the display_facet or not
  #
  # By default, only render facets with items.
  # @param [RSolr::Ext::Response::Facets::FacetField] display_facet 
  def should_render_facet? display_facet
    # display when show is nil or true
    display = facet_configuration_for_field(display_facet.name).show != false
    return display && display_facet.items.present?
  end

  # the name of the partial to use to render a facet field. Can be over-ridden for custom
  # display on a per-facet basis. 
  def facet_partial_name(display_facet = nil)
    name = facet_configuration_for_field(display_facet.name).try(:partial)
    name ||= "facet_limit"
  end

  #
  # facet param helpers ->
  #

  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens. 
  # first arg item is a facet value item from rsolr-ext.
  # options consist of:
  # :suppress_link => true # do not make it a link, used for an already selected value for instance
  def render_facet_value(facet_solr_field, item, options ={})    
    (link_to_unless(options[:suppress_link], item.value, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select label") + " " + render_facet_count(item.hits)).html_safe
  end

  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value(facet_solr_field, item)
    content_tag(:span, render_facet_value(facet_solr_field, item, :suppress_link => true), :class => "selected label") +
      link_to("[remove]", remove_facet_params(facet_solr_field, item.value, params), :class=>"remove")
  end

  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style, for instance not use parens. And can be called
  # by plugins to get consistent display. 
  def render_facet_count(num)
    content_tag("span",  "(" + format_num(num) + ")", :class => "count") 
  end
  
  # adds the value and/or field to params[:f]
  # Does NOT remove request keys and otherwise ensure that the hash
  # is suitable for a redirect. See
  # add_facet_params_and_redirect
  def add_facet_params(field, value)
    p = params.dup
    p[:f] = (p[:f] || {}).dup # the command above is not deep in rails3, !@#$!@#$
    p[:f][field] = (p[:f][field] || []).dup
    p[:f][field].push(value)
    p
  end

  # Used in catalog/facet action, facets.rb view, for a click
  # on a facet value. Add on the facet params to existing
  # search constraints. Remove any paginator-specific request
  # params, or other request params that should be removed
  # for a 'fresh' display. 
  # Change the action to 'index' to send them back to
  # catalog/index with their new facet choice. 
  def add_facet_params_and_redirect(field, value)
    new_params = add_facet_params(field, value)

    # Delete page, if needed. 
    new_params.delete(:page)

    # Delete any request params from facet-specific action, needed
    # to redir to index action properly. 
    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key| 
      new_params.delete(paginator_key)
    end
    new_params.delete(:id)

    # Force action to be index. 
    new_params[:action] = "index"
    new_params    
  end
  # copies the current params (or whatever is passed in as the 3rd arg)
  # removes the field value from params[:f]
  # removes the field if there are no more values in params[:f][field]
  # removes additional params (page, id, etc..)
  def remove_facet_params(field, value, source_params=params)
    p = source_params.dup
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p[:f] = (p[:f] || {}).dup
    p[:f][field] = (p[:f][field] || []).dup
    p.delete :page
    p.delete :id
    p.delete :counter
    p.delete :commit
    p[:f][field] = p[:f][field] - [value]
    p[:f].delete(field) if p[:f][field].size == 0
    p
  end
  
  # true or false, depending on whether the field and value is in params[:f]
  def facet_in_params?(field, value)
    params[:f] and params[:f][field] and params[:f][field].include?(value)
  end
  
end
