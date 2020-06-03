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
  # Check if the query has any constraints defined (a query, facet, etc)
  #
  # @param [Hash] localized_params query parameters
  # @return [Boolean]
  def query_has_constraints?(params_or_search_state = search_state)
    search_state = convert_to_search_state(params_or_search_state)
    search_state.has_constraints?
  end
  deprecation_deprecate query_has_constraints?: 'use search_state#has_constraints?'

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
  # @param [ActionController::Parameters] localized_params query parameters
  # @return [String]
  def render_constraints_query(params_or_search_state = search_state)
    search_state = convert_to_search_state(params_or_search_state)

    # So simple don't need a view template, we can just do it here.
    return "".html_safe if search_state.query_param.blank?

    Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
      render_constraint_element(constraint_query_label(search_state),
                                search_state.query_param,
                                classes: ["query"],
                                remove: remove_constraint_url(search_state))
    end
  end
  deprecation_deprecate :render_constraints_query

  ##
  # Provide a url for removing a particular constraint. This can be overriden
  # in the case that you want parameters other than the defaults to be removed
  # (e.g. :search_field)
  #
  # @param [ActionController::Parameters] localized_params query parameters
  # @return [String]
  def remove_constraint_url(params_or_search_state = search_state)
    search_state = convert_to_search_state(params_or_search_state)

    search_action_path(search_state.remove_query_params)
  end
  deprecation_deprecate :remove_constraint_url

  ##
  # Render the facet constraints
  # @param [Hash] localized_params query parameters
  # @return [String]
  def render_constraints_filters(params_or_search_state = search_state)
    search_state = convert_to_search_state(params_or_search_state)

    return "".html_safe if search_state.filter_params.blank?

    Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
      safe_join(search_state.filter_params.each_pair.map do |facet, values|
        render_filter_element(facet, values, search_state)
      end, "\n")
    end
  end
  deprecation_deprecate :render_constraints_filters

  ##
  # Render a single facet's constraint
  # @param [String] facet field
  # @param [Array<String>] values selected facet values
  # @param [Blacklight::SearchState] path query parameters (unused)
  # @return [String]
  def render_filter_element(facet, values, search_state)
    facet_config = facet_configuration_for_field(facet)

    safe_join(Array(values).map do |val|
      next if val.blank? # skip empty string

      presenter = facet_item_presenter(facet_config, val, facet)

      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
        render_constraint_element(facet_field_label(facet_config.key),
                                  presenter.label,
                                  remove: presenter.remove_href(search_state),
                                  classes: ["filter", "filter-" + facet.parameterize])
      end
    end, "\n")
  end
  deprecation_deprecate :render_filter_element

  # Render a label/value constraint on the screen. Can be called
  # by plugins and such to get application-defined rendering.
  #
  # Can be over-ridden locally to render differently if desired,
  # although in most cases you can just change CSS instead.
  #
  # Can pass in nil label if desired.
  #
  # @param [String] label to display
  # @param [String] value to display
  # @param [Hash] options
  # @option options [String] :remove url to execute for a 'remove' action
  # @option options [Array<String>] :classes an array of classes to add to container span for constraint.
  # @return [String]
  def render_constraint_element(label, value, options = {})
    render(partial: "catalog/constraints_element", locals: { label: label, value: value, options: options })
  end
  deprecation_deprecate :render_constraint_element

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
