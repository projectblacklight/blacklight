# All methods in here are 'api' that may be over-ridden by plugins and local
# code, so method signatures and semantics should not be changed casually.
# implementations can be of course.
#
# Includes methods for rendering contraints graphically on the
# search results page (render_constraints(_*)), and also
# for rendering more textually on Search History page
# (render_search_to_s(_*))
module RenderConstraintsHelper

  # Render actual constraints, not including header or footer
  # info. 
  def render_constraints(localized_params = params)
    render_constraints_query(localized_params) + render_constraints_filters(localized_params)
  end
  
  def render_constraints_query(localized_params = params)
    # So simple don't need a view template, we can just do it here.
    if (!localized_params[:q].blank?)
      label = 
        if (params[:search_field] == Blacklight.default_search_field[:key] or params[:search_field].blank? )
          nil
        else
          Blacklight.label_for_search_field(params[:search_field])
        end
    
      render_constraint_element(label,
            localized_params[:q], 
            :classes => ["query"], 
            :remove => catalog_index_path(localized_params.merge(:q=>nil, :action=>'index')))
    else
      ""
    end
  end

  def render_constraints_filters(localized_params = params)
     return "" unless localized_params[:f]
     content = ""
     localized_params[:f].each_pair do |facet,values|
        values.each do |val|
           content << render_constraint_element( facet_field_labels[facet],
                  val, 
                  :remove => catalog_index_path(remove_facet_params(facet, val, localized_params)),
                  :classes => ["filter", "filter-" + facet.parameterize] 
                ) + "\n"                 					            
				end
     end 

     return content    
  end

  # Render a label/value constraint on the screen. Can be called
  # by plugins and such to get application-defined rendering.
  #
  # Can be over-ridden locally to render differently if desired,
  # although in most cases you can just change CSS instead.
  #
  # Can pass in nil label if desired.
  #
  # options:
  # [:remove]
  #    url to execute for a 'remove' action  
  # [:classes] 
  #    can be an array of classes to add to container span for constraint.
  # [:escape_label]
  #    default true, HTML escape.
  # [:escape_value]
  #    default true, HTML escape. 
  def render_constraint_element(label, value, options = {})
    render(:partial => "catalog/constraints_element", :locals => {:label => label, :value => value, :options => options})    
  end


  # Simpler textual version of constraints, used on Search History page.
  # Theoretically can may be DRY'd up with results page render_constraints,
  # maybe even using the very same HTML with different CSS? 
  # But too tricky for now, too many changes to existing CSS. TODO.  
  def render_search_to_s(params)
    render_search_to_s_q(params) +
    render_search_to_s_filters(params)
  end

  def render_search_to_s_q(params)
    return "" if params[:q].blank?
    
    label = (params[:search_field] == Blacklight.default_search_field[:key]) ? 
      nil :
      Blacklight.label_for_search_field(params[:search_field])
    
    render_search_to_s_element(label , params[:q] )        
  end
  def render_search_to_s_filters(params)
    return "" unless params[:f]

    params[:f].collect do |facet_field, value_list|
      render_search_to_s_element(Blacklight.config[:facet][:labels][facet_field],
        value_list.collect do |value|
          "<span class='filterValue'>#{h(value)}</span>"
        end.join(" <span class='label'>and</span> "),
        :escape_value => false
      )    
    end.join(" \n ")    
  end

  # value can be Array, in which case elements are joined with
  # 'and'.   Pass in option :escape_value => false to pass in pre-rendered
  # html for value. key with escape_key if needed.  
  def render_search_to_s_element(key, value, options = {})
    options[:escape_value] = true unless options.has_key?(:escape_value)
    options[:escape_key] = true unless options.has_key?(:escape_key)
    
    key = h(key) if options[:escape_key]
    value = h(value) if options[:escape_value]
    
     "<span class='constraint'>" +
     (key.blank? ? "" : "<span class='filterName'>#{key}:</span>")  +
     "<span class='filterValue'>#{value}</span></span>"
  end
  
end
