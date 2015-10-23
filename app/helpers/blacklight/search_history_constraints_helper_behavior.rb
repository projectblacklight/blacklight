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

  ##
  # Render the search query constraint
  def render_search_to_s_q(params)
    return "".html_safe if params['q'].blank?

    label = label_for_search_field(params[:search_field]) unless default_search_field && params[:search_field] == default_search_field[:key]

    render_search_to_s_element(label , render_filter_value(params['q']) )
  end

  ##
  # Render the search facet constraints
  def render_search_to_s_filters(params)
    return "".html_safe unless params[:f]

    safe_join(params[:f].collect do |facet_field, value_list|
      render_search_to_s_element(facet_field_label(facet_field),
        safe_join(value_list.collect do |value|
          render_filter_value(value, facet_field)
        end, content_tag(:span, " #{t('blacklight.and')} ", :class =>'filterSeparator'))
      )    
    end, " \n ")
  end

  # value can be Array, in which case elements are joined with
  # 'and'.   Pass in option :escape_value => false to pass in pre-rendered
  # html for value. key with escape_key if needed.  
  def render_search_to_s_element(key, value, options = {})
    content_tag(:span, render_filter_name(key) + content_tag(:span, value, :class => 'filterValues'), :class => 'constraint')
  end

  ##
  # Render the name of the facet
  def render_filter_name name
    return "".html_safe if name.blank?
    content_tag(:span, t('blacklight.search.filters.label', :label => name), :class => 'filterName')
  end

  ##
  # Render the value of the facet
  def render_filter_value value, key = nil
    display_value = value
    display_value = facet_display_value(key, value) if key
    content_tag(:span, h(display_value), :class => 'filterValue')
  end

end
