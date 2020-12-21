# frozen_string_literal: true

module Blacklight
  class SearchBarComponent < ::ViewComponent::Base
    with_content_areas :append, :prepend

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      url:, params:, classes: ['search-query-form'], presenter: nil,
      prefix: '', method: 'GET', q: nil, query_param: :q,
      search_field: nil, autocomplete_path: nil,
      autofocus: nil, i18n: { scope: 'blacklight.search.form' }
    )
      @url = url
      @q = q || params[:q]
      @query_param = query_param
      @search_field = search_field || params[:search_field]
      @params = params.except(:q, :search_field, :utf8, :page)
      @prefix = prefix
      @classes = classes
      @presenter = presenter
      @method = method
      @autocomplete_path = autocomplete_path
      @autofocus = autofocus
      @i18n = i18n
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

    def search_fields
      @search_fields ||= blacklight_config.search_fields.values
                                          .select { |field_def| helpers.should_render_field?(field_def) }
                                          .collect { |field_def| [helpers.label_for_search_field(field_def.key), field_def.key] }
    end

    private

    def presenter
      @presenter ||= blacklight_config.index.search_bar_presenter_class.new(controller, blacklight_config)
    end

    def blacklight_config
      @view_context.blacklight_config
    end

    ##
    # Writes out zero or more <input type="hidden"> elements, completely
    # representing a hash passed in using Rails-style request parameters
    # for hashes nested with arrays and other hashes.
    #
    # @param [Hash] hash
    # @return [String]
    def render_hash_as_hidden_fields(hash)
      hidden_fields = []
      flatten_hash(hash).each do |name, value|
        value = Array.wrap(value)
        value.each do |v|
          hidden_fields << hidden_field_tag(name, v.to_s, id: nil)
        end
      end

      safe_join(hidden_fields, "\n")
    end

    def flatten_hash(hash = params, ancestor_names = [])
      flat_hash = {}
      hash.each do |k, v|
        names = Array.new(ancestor_names)
        names << k
        if v.is_a?(Hash)
          flat_hash.merge!(flatten_hash(v, names))
        else
          key = flat_hash_key(names)
          key += "[]" if v.is_a?(Array)
          flat_hash[key] = v
        end
      end

      flat_hash
    end

    def flat_hash_key(names)
      names = Array.new(names)
      name = names.shift.to_s.dup
      names.each do |n|
        name << "[#{n}]"
      end
      name
    end

    def scoped_t(key, **args)
      t(key, default: t(key, scope: 'blacklight.search.form'), **@i18n, **args)
    end
  end
end
