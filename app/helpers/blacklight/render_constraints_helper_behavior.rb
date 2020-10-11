# frozen_string_literal: true
# All methods in here are 'api' that may be over-ridden by plugins and local
# code, so method signatures and semantics should not be changed casually.
# implementations can be of course.
#
# Includes methods for rendering contraints graphically on the
# search results page (render_constraints(_*))
module Blacklight::RenderConstraintsHelperBehavior
  extend Deprecation
  self.deprecation_horizon = 'blacklight 8.0'

  ##
  # Render the actual constraints, not including header or footer
  # info.
  #
  # @param [Hash] localized_params query parameters
  # @return [String]
  def render_constraints(localized_params = params, local_search_state = search_state)
    params_or_search_state = if localized_params != params
                               localized_params
                             else
                               local_search_state
                             end

    Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
      render_constraints_query(params_or_search_state) + render_constraints_filters(params_or_search_state)
    end
  end

  ##
  # Render the query constraints
  #
  # @deprecated
  # @param [Blacklight::SearchState,ActionController::Parameters] params_or_search_state query parameters
  # @return [String]
  def render_constraints_query(params_or_search_state = search_state)
    Deprecation.warn(Blacklight::RenderConstraintsHelperBehavior, 'render_constraints_query is deprecated')
    search_state = convert_to_search_state(params_or_search_state)

    # So simple don't need a view template, we can just do it here.
    return "".html_safe if search_state.query_param.blank?

    render(partial: "catalog/constraints_element", locals: {
      label: constraint_query_label(search_state.params),
      value: search_state.query_param,
      options: {
        classes: ["query"],
        remove: remove_constraint_url(search_state)
      }
    })
  end

  ##
  # Provide a url for removing a particular constraint. This can be overriden
  # in the case that you want parameters other than the defaults to be removed
  # (e.g. :search_field)
  #
  # @deprecated
  # @param [Blacklight::SearchState,ActionController::Parameters] params_or_search_state query parameters
  # @return [String]
  def remove_constraint_url(params_or_search_state = search_state)
    Deprecation.warn(Blacklight::RenderConstraintsHelperBehavior, 'remove_constraint_url is deprecated')
    search_state = convert_to_search_state(params_or_search_state)

    search_action_path(search_state.remove_query_params)
  end

  ##
  # Render the facet constraints
  # @deprecated
  # @param [Blacklight::SearchState,Hash] params_or_search_state query parameters
  # @return [String]
  def render_constraints_filters(params_or_search_state = search_state)
    Deprecation.warn(Blacklight::RenderConstraintsHelperBehavior, 'render_constraints_filters is deprecated')
    search_state = convert_to_search_state(params_or_search_state)

    return "".html_safe if search_state.filter_params.blank?

    Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
      safe_join(search_state.filter_params.each_pair.map do |facet, values|
        render_filter_element(facet, values, search_state)
      end, "\n")
    end
  end

  ##
  # Render a single facet's constraint
  # @deprecated
  # @param [String] facet field
  # @param [Array<String>] values selected facet values
  # @param [Blacklight::SearchState] search_state path query parameters
  # @return [String]
  def render_filter_element(facet, values, search_state)
    Deprecation.warn(Blacklight::RenderConstraintsHelperBehavior, 'render_filter_element is deprecated')
    facet_config = facet_configuration_for_field(facet)

    safe_join(Array(values).map do |val|
      next if val.blank? # skip empty string

      presenter = facet_item_presenter(facet_config, val, facet)

      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
        render(partial: "catalog/constraints_element", locals: {
          label: presenter.field_label,
          value: presenter.label,
          options: {
            remove: presenter.remove_href(search_state),
            classes: ["filter", "filter-" + facet.parameterize]
          }
        })
      end
    end, "\n")
  end

  private

  def convert_to_search_state(params_or_search_state)
    if params_or_search_state.is_a? Blacklight::SearchState
      params_or_search_state
    else
      # deprecated
      controller.search_state_class.new(params_or_search_state, blacklight_config, controller)
    end
  end
end
