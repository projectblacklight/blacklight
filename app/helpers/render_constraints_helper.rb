module RenderConstraintsHelper

  def render_constraints(localized_params = params)
    render_constraints_query(localized_params) + render_constraints_filters(localized_params)
  end
  
  def render_constraints_query(localized_params = params)
    # So simple don't need a view template, we can just do it here.
    if (!localized_params[:q].blank?)
      render_constraint_element(search_field_label(localized_params),
            localized_params[:q], 
            :classes => ["query"], 
            :remove => catalog_index_path(localized_params.merge(:q=>nil, :action=>'index')))
    else
      render_constraint_element(nil, "No Keywords", :classes => ["query"], :check => false)
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
                  :classes => ["filter"] 
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
  # label and value will be HTML-escaped, pass in raw.
  # Can pass in nil label if desired.
  #
  # options:
  # [:remove]
  #    url to execute for a 'remove' action  
  # [:classes] 
  #    can be an array of classes to add to container span for constraint. 
  def render_constraint_element(label, value, options = {})
    render(:partial => "catalog/constraints_element", :locals => {:label => label, :value => value, :options => options})    
  end
  
end
