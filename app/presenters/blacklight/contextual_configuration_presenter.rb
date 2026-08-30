# frozen_string_literal: true

module Blacklight
  class ContextualConfigurationPresenter
    attr_reader :blacklight_config, :view_context

    delegate_missing_to :blacklight_config

    delegate :params, :action_name, to: :view_context

    # These methods may be good candidates to move up to this class
    delegate :logo_link, :default_per_page, :default_search_field,
             :facet_configuration_for_field, :facet_field_names, :facet_fields_in_group,
             :facet_group_names,
             to: :blacklight_config

    def initialize(blacklight_config, view_context:)
      @blacklight_config = blacklight_config
      @view_context = view_context
    end

    def sort_fields
      blacklight_config.sort_fields.select { |_sort_key, field_config| should_render_field?(field_config) }
    end

    def current_sort_field
      sort_fields[params[:sort]] || default_sort_field
    end

    def default_sort_field
      (sort_fields.find { |_k, config| config.respond_to?(:default) && config.default } || sort_fields.first)&.last
    end

    def search_fields
      blacklight_config.search_fields.select { |_search_key, field_config| should_render_field?(field_config) }
    end

    def view_config
      blacklight_config.view_config(current_index_view, action_name: action_name)
    end

    def index_views
      blacklight_config.view.select do |_k, config|
        should_render_field? config
      end
    end

    # filter #index_views to just views that should display in the view type control
    def index_view_options
      index_views.select do |_k, config|
        config.display_control.nil? || blacklight_configuration_context.evaluate_configuration_conditional(config.display_control)
      end
    end

    def default_index_view
      index_views.select { |_k, config| config.respond_to?(:default) && config.default }.keys.first || index_views.keys.first
    end

    ##
    # Get the current "view type" (and ensure it is a valid type)
    #
    # @param [Hash] query_params the query parameters to check
    # @return [Symbol] (e.g. :index, :gallery)
    def current_index_view query_params = params || {}
      view_param = query_params[:view]
      view_param ||= view_context.session[:preferred_view] if view_context.respond_to?(:session)
      if view_param && index_views.key?(view_param.to_sym)
        view_param.to_sym
      else
        default_index_view
      end
    end

    def should_render_field?(field_config, *)
      blacklight_configuration_context.evaluate_if_unless_configuration(field_config, *)
    end

    delegate :blacklight_configuration_context, to: :view_context
  end
end
