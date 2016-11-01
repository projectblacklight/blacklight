# frozen_string_literal: true
# All methods in here are 'api' that may be over-ridden by plugins and local
# code, so method signatures and semantics should not be changed casually.
# implementations can be of course.
#
# Includes methods for rendering contraints graphically on the
# search results page (render_constraints(_*))
module Blacklight::RenderConstraintsHelperBehavior
  ##
  # Check if the query has any constraints defined (a query, facet, etc)
  #
  # @param [Hash] localized_params query parameters
  # @return [Boolean]
  def query_has_constraints?(localized_params = params)
    !(localized_params[:q].blank? && localized_params[:f].blank?)
  end

  ##
  # Render the actual constraints, not including header or footer
  # info.
  #
  # @param [Hash] localized_params query parameters
  # @return [String]
  def render_constraints(localized_params = params)
    render_constraints_query(localized_params) + render_constraints_filters(localized_params)
  end

  ##
  # Render the query constraints
  #
  # @param [ActionController::Parameters] localized_params query parameters
  # @return [String]
  def render_constraints_query(localized_params = params)
    # So simple don't need a view template, we can just do it here.
    return "".html_safe if localized_params[:q].blank?

    render_constraint_element(constraint_query_label(localized_params),
          localized_params[:q],
          classes: ["query"],
          remove: remove_constraint_url(localized_params))
  end

  ##
  # Provide a url for removing a particular constraint. This can be overriden
  # in the case that you want parameters other than the defaults to be removed
  # (e.g. :search_field)
  #
  # @param [ActionController::Parameters] localized_params query parameters
  # @return [String]
  def remove_constraint_url(localized_params)
    scope = localized_params.delete(:route_set) || self

    unless localized_params.is_a? ActionController::Parameters
      localized_params = ActionController::Parameters.new(localized_params)
    end

    options = localized_params.merge(q: nil, action: 'index')
    options.permit!
    scope.url_for(options)
  end

  ##
  # Render the facet constraints
  # @param [Hash] localized_params query parameters
  # @return [String]
  def render_constraints_filters(localized_params = params)
     return "".html_safe unless localized_params[:f]
     path = Blacklight::SearchState.new(localized_params, blacklight_config)
     content = []
     localized_params[:f].each_pair do |facet,values|
       content << render_filter_element(facet, values, path)
     end

     safe_join(content.flatten, "\n")
  end

  ##
  # Render a single facet's constraint
  # @param [String] facet field
  # @param [Array<String>] values selected facet values
  # @param [Blacklight::SearchState] path query parameters
  # @return [String]
  def render_filter_element(facet, values, path)
    facet_config = facet_configuration_for_field(facet)

    safe_join(Array(values).map do |val|
      next if val.blank? # skip empty string
      render_constraint_element(facet_field_label(facet_config.key),
                                facet_display_value(facet, val),
                                remove: search_action_path(path.remove_facet_params(facet, val)),
                                classes: ["filter", "filter-" + facet.parameterize])
    end, "\n")
  end

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
    render(:partial => "catalog/constraints_element", :locals => {:label => label, :value => value, :options => options})
  end
end
