# frozen_string_literal: true

module Blacklight
  class ClausePresenter
    attr_reader :key, :user_parameters, :field_config, :view_context, :search_state

    def initialize(key, user_parameters, field_config, view_context, search_state = view_context.search_state)
      @key = key
      @user_parameters = user_parameters
      @field_config = field_config
      @view_context = view_context
      @search_state = search_state
    end

    def field_label
      field_config.display_label('search')
    end

    ##
    # Get the displayable version of a facet's value
    #
    # @return [String]
    def label
      user_parameters[:query]
    end

    def remove_href(path = search_state)
      view_context.search_action_path(path.reset_search(clause: path.clause_params.except(key)))
    end

    private

    def facet_field_presenter
      @facet_field_presenter ||= view_context.facet_field_presenter(facet_config, {})
    end
  end
end
