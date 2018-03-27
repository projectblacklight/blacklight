# frozen_string_literal: true

module Blacklight
  # Renders contraints graphically on the search results page
  class ConstraintsPresenter
    # @param [ActionController::Parameters] params query parameters
    # @param [#search_action_path] view_context the view
    def initialize(params, view_context, route_set = view_context)
      @params = params
      @view_context = view_context
      @route_set = route_set
    end

    attr_reader :params, :view_context, :route_set

    delegate :facet_configuration_for_field, :search_state, :search_action_path,
             :safe_join, :default_search_field, :search_field, to: :view_context
    ##
    # Render the actual constraints, not including header or footer
    # info.
    #
    # @return [String]
    def render
      render_constraints_query + render_constraints_filters
    end

    private

    ##
    # Render the facet constraints
    # @return [String]
    def render_constraints_filters
      return "".html_safe unless params[:f]
      path = search_state
      content = []
      params[:f].each_pair do |facet, values|
        content << render_filter_element(facet, values, path)
      end

      safe_join(content.flatten, "\n")
    end

    ##
    # Render the query constraints
    #
    # @param [ActionController::Parameters] localized_params query parameters
    # @return [String]
    def render_constraints_query
      # So simple don't need a view template, we can just do it here.
      return "".html_safe if params[:q].blank?

      render_constraint_element(constraint_query_label,
                                params[:q],
                                classes: ["query"],
                                remove: remove_constraint_url)
    end

    ##
    # Return a label for the currently selected search field.
    # If no "search_field" or the default (e.g. "all_fields") is selected, then return nil
    # Otherwise grab the label of the selected search field.
    # @return [String]
    def constraint_query_label
      search_field(params[:search_field]) unless default_search_field?(params[:search_field])
    end

    ##
    # Is the search form using the default search field ("all_fields" by default)?
    # @param [String] selected_search_field the currently selected search_field
    # @return [Boolean]
    def default_search_field?(selected_search_field)
      selected_search_field.blank? || (default_search_field && selected_search_field == default_search_field[:key])
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
        render_constraint_element(facet_config.facet_field_label,
                                  # TODO: this shares code with FacetItemPresenter#facet_display_value
                                  FacetItemPresenter.facet_value_presenter.new(facet, val, self).display,
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
      view_context.render "catalog/constraints_element", label: label, value: value, options: options
    end

    ##
    # Provide a url for removing a particular constraint. This can be overriden
    # in the case that you want parameters other than the defaults to be removed
    # (e.g. :search_field)
    #
    # @return [String]
    def remove_constraint_url
      options = params.merge(q: nil, action: 'index')
      options.permit!
      route_set.url_for(options)
    end
  end
end
