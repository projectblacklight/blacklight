# frozen_string_literal: true

module Blacklight
  class SearchBarComponent < ::ViewComponent::Base
    # rubocop:disable Metrics/ParameterLists
    def initialize(url:, params:, classes: ['search-query-form'], presenter: nil, prefix: '', method: 'GET', q: nil, search_field: nil, search_fields: [], autocomplete_path: nil, autofocus: nil)
      @url = url
      @q = q || params[:q]
      @search_field = search_field || params[:search_field]
      @params = params.except(:q, :search_field, :utf8, :page)
      @prefix = prefix
      @classes = classes
      @presenter = presenter
      @method = method
      @autocomplete_path = autocomplete_path
      @autofocus = autofocus
      @search_fields = search_fields
    end
    # rubocop:enable Metrics/ParameterLists

    def autocomplete_path
      return nil unless presenter.autocomplete_enabled?

      @autocomplete_path
    end

    def autofocus
      if @autofocus.nil?
        presenter.autofocus?
      else
        @autofocus
      end
    end

    private

    def presenter
      @presenter ||= blacklight_config.index.search_bar_presenter_class.new(controller, blacklight_config)
    end

    def blacklight_config
      @view_context.blacklight_config
    end

    def render_hash_as_hidden_fields(*args)
      Deprecation.silence(Blacklight::HashAsHiddenFieldsHelperBehavior) do
        @view_context.render_hash_as_hidden_fields(*args)
      end
    end
  end
end
