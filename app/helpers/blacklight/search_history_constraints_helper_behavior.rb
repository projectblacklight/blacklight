# -*- encoding : utf-8 -*-
# All methods in here are 'api' that may be over-ridden by plugins and local
# code, so method signatures and semantics should not be changed casually.
# implementations can be of course.
#
# Includes methods for rendering more textually on Search History page
# (render_search_to_s(_*))
module Blacklight::SearchHistoryConstraintsHelperBehavior

  # Simpler textual version of constraints, used on Search History page.
  # Theoretically can may be DRY'd up with results page render_constraints,
  # maybe even using the very same HTML with different CSS? 
  # But too tricky for now, too many changes to existing CSS. TODO.  
  def render_search_to_s(params)
    render_search_to_s_q(params) +
    render_search_to_s_filters(params)
  end

  def render_search_to_s_q(params)
    return "".html_safe if params[:q].blank?
    
    if default_search_field && params[:search_field] != default_search_field[:key]
      label = label_for_search_field(params[:search_field])
    end

    render_search_to_s_element(label , params[:q] )        
  end
  def render_search_to_s_filters(params)
    return "".html_safe unless params[:f]

    params[:f].collect do |facet_field, value_list|
      render_search_to_s_element(blacklight_config.facet_fields[facet_field].label,
        value_list.collect do |value|
          render_filter_value(value)
        end.join(content_tag(:span, 'and', :class =>'label')).html_safe
      )    
    end.join(" \n ").html_safe    
  end

  # value can be Array, in which case elements are joined with
  # 'and'.   Pass in option :escape_value => false to pass in pre-rendered
  # html for value. key with escape_key if needed.  
  def render_search_to_s_element(key, value, options = {})
    content_tag(:span, render_filter_name(key) + render_filter_value(value), :class => 'constraint')
  end

  def render_filter_name name
    return "".html_safe if name.blank?
    content_tag(:span, h(name) + ":", :class => 'filterName')
  end

  def render_filter_value value
    content_tag(:span, h(value), :class => 'filterValue')
  end

end
