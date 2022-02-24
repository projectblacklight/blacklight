# frozen_string_literal: true
# All methods in here are 'api' that may be over-ridden by plugins and local
# code, so method signatures and semantics should not be changed casually.
# implementations can be of course.
#
# Includes methods for rendering more textually on Search History page
# (render_search_to_s(_*))
module Blacklight::SearchHistoryConstraintsHelperBehavior
  extend Deprecation
  self.deprecation_horizon = '8.0'

  # Simpler textual version of constraints, used on Search History page.
  # Theoretically can may be DRY'd up with results page render_constraints,
  # maybe even using the very same HTML with different CSS?
  # But too tricky for now, too many changes to existing CSS. TODO.
  def render_search_to_s(params)
    return render(Blacklight::ConstraintsComponent.for_search_history(search_state: convert_to_search_state(params))) unless overridden_search_history_constraints_helper_methods?

    Deprecation.warn(Blacklight::SearchHistoryConstraintsHelperBehavior, 'Calling out to potentially overridden helpers for backwards compatibility.')

    Deprecation.silence(Blacklight::SearchHistoryConstraintsHelperBehavior) do
      render_search_to_s_q(params) +
      render_search_to_s_filters(params)
    end
  end
  deprecation_deprecate render_search_to_s: 'Use Blacklight::ConstraintsComponent.for_search_history instead'

  ##
  # Render the search query constraint
  def render_search_to_s_q(params)
    Deprecation.warn(Blacklight::SearchHistoryConstraintsHelperBehavior, '#render_search_to_s_q is deprecated without replacement')
    return "".html_safe if params['q'].blank?

    label = label_for_search_field(params[:search_field]) unless default_search_field?(params[:search_field])

    render_search_to_s_element(label, render_filter_value(params['q']))
  end

  ##
  # Render the search facet constraints
  def render_search_to_s_filters(params)
    Deprecation.warn(Blacklight::SearchHistoryConstraintsHelperBehavior, '#render_search_to_s_filters is deprecated without replacement')
    return "".html_safe unless params[:f]

    safe_join(params[:f].collect do |facet_field, value_list|
      render_search_to_s_element(facet_field_label(facet_field),
                                 safe_join(value_list.collect do |value|
                                   render_filter_value(value, facet_field)
                                 end,
                                           tag.span(" #{t('blacklight.and')} ", class: 'filter-separator')))
    end, " \n ")
  end

  # value can be Array, in which case elements are joined with
  # 'and'.   Pass in option :escape_value => false to pass in pre-rendered
  # html for value. key with escape_key if needed.
  def render_search_to_s_element(key, value, _options = {})
    Deprecation.warn(Blacklight::SearchHistoryConstraintsHelperBehavior, '#render_search_to_s_element is deprecated without replacement')
    tag.span(render_filter_name(key) + tag.span(value, class: 'filter-values'),
             class: 'constraint')
  end

  ##
  # Render the name of the facet
  def render_filter_name name
    Deprecation.warn(Blacklight::SearchHistoryConstraintsHelperBehavior, '#render_filter_name is deprecated without replacement')
    return "".html_safe if name.blank?

    tag.span(t('blacklight.search.filters.label', label: name),
             class: 'filter-name')
  end

  ##
  # Render the value of the facet
  def render_filter_value value, key = nil
    Deprecation.warn(Blacklight::SearchHistoryConstraintsHelperBehavior, '#render_filter_value is deprecated without replacement')
    display_value = value
    Deprecation.silence(Blacklight::FacetsHelperBehavior) do
      display_value = facet_display_value(key, value) if key
    end
    tag.span(h(display_value),
             class: 'filter-value')
  end

  private

  # Check if the downstream application has overridden these methods
  # @deprecated
  # @private
  def overridden_search_history_constraints_helper_methods?
    method(:render_search_to_s_q).owner != Blacklight::FacetsHelperBehavior ||
      method(:render_search_to_s_filters).owner != Blacklight::FacetsHelperBehavior ||
      method(:render_search_to_s_element).owner != Blacklight::FacetsHelperBehavior ||
      method(:render_filter_name).owner != Blacklight::FacetsHelperBehavior ||
      method(:render_filter_value).owner != Blacklight::FacetsHelperBehavior
  end
end
