# frozen_string_literal: true

module Blacklight
  class SearchBarComponent < Blacklight::Component
    include Blacklight::ContentAreasShim

    renders_one :append
    renders_one :prepend

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      url:, params:,
      advanced_search_url: nil, presenter: nil,
      classes: ['search-query-form'], prefix: nil,
      method: 'GET', q: nil, query_param: :q,
      search_field: nil, search_fields: nil, autocomplete_path: nil,
      autofocus: nil, i18n: { scope: 'blacklight.search.form' }
    )
      @url = url
      @advanced_search_url = advanced_search_url
      @q = q || params[:q]
      @query_param = query_param
      @search_field = search_field || params[:search_field]
      @params = params.except(:q, :search_field, :utf8, :page)
      @prefix = prefix
      @classes = classes
      @method = method
      @autocomplete_path = autocomplete_path
      @autofocus = autofocus
      @search_fields = search_fields
      @i18n = i18n
      return if presenter.nil?

      Deprecation.warn(self, 'SearchBarComponent no longer uses a SearchBarPresenter, the presenter: param will be removed in 8.0. ' \
                             'Set advanced_search.enabled, autocomplete_enabled, and enable_search_bar_autofocus on BlacklightConfiguration')
    end
    # rubocop:enable Metrics/ParameterLists

    def autocomplete_path
      return nil unless blacklight_config.autocomplete_enabled

      @autocomplete_path
    end

    def autofocus
      if @autofocus.nil?
        blacklight_config.enable_search_bar_autofocus &&
          controller.is_a?(Blacklight::Catalog) &&
          controller.action_name == "index" &&
          !controller.has_search_parameters?
      else
        @autofocus
      end
    end

    def search_fields
      @search_fields ||= blacklight_config.search_fields.values
                                          .select { |field_def| helpers.should_render_field?(field_def) }
                                          .collect { |field_def| [helpers.label_for_search_field(field_def.key), field_def.key] }
    end

    def advanced_search_enabled?
      blacklight_config.advanced_search.enabled
    end

    private

    def blacklight_config
      helpers.blacklight_config
    end

    def render_hash_as_hidden_fields(*args)
      Deprecation.silence(Blacklight::HashAsHiddenFieldsHelperBehavior) do
        helpers.render_hash_as_hidden_fields(*args)
      end
    end

    def scoped_t(key, **args)
      t(key, default: t(key, scope: 'blacklight.search.form'), **@i18n, **args)
    end
  end
end
