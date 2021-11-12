# frozen_string_literal: true

module Blacklight
  class SearchState
    # Modeling access to filter query parameters
    class FilterField
      # @param [Blacklight::Configuration::FacetField] config
      attr_reader :config

      # @param [Blacklight::SearchState] search_state
      attr_reader :search_state

      # @return [String,Symbol]
      delegate :key, to: :config

      # @param [Blacklight::Configuration::FacetField] config
      # @param [Blacklight::SearchState] search_state
      def initialize(config, search_state)
        @config = config
        @search_state = search_state
      end

      # @param [String,#value] a filter item to add to the url
      # @return [Blacklight::SearchState] new state
      def add(item)
        new_state = search_state.reset_search

        if item.try(:missing)
          # if this is a 'missing' facet value, the :fq is only for backwards compatibility
        elsif item.respond_to?(:fq)
          Array(item.fq).each do |f, v|
            new_state = new_state.filter(f).add(v)
          end
        end

        if item.respond_to?(:field) && item.field != key
          return new_state.filter(item.field).add(item)
        end

        url_key = key
        params = new_state.params
        param = :f
        value = as_url_parameter(item)

        if value.is_a?(Hash) && value[:missing]
          url_key = "-#{key}"
          value = Blacklight::Engine.config.facet_missing_param
        end

        param = :f_inclusive if value.is_a?(Array)

        # value could be a string
        params[param] = (params[param] || {}).dup

        if value.is_a? Array
          params[param][url_key] = value
        elsif config.single
          params[param][url_key] = [value]
        else
          params[param][url_key] = Array(params[param][url_key] || []).dup
          params[param][url_key].push(value)
        end

        new_state.reset(params)
      end

      # @param [String,#value] a filter to remove from the url
      # @return [Blacklight::SearchState] new state
      def remove(item)
        new_state = search_state.reset_search
        if item.respond_to?(:field) && item.field != key
          return new_state.filter(item.field).remove(item)
        end

        url_key = config.key
        params = new_state.params

        param = :f
        value = as_url_parameter(item)

        if value.is_a?(Hash) && value[:missing]
          url_key = "-#{key}"
          value = Blacklight::Engine.config.facet_missing_param
        end

        param = :f_inclusive if value.is_a?(Array)

        # need to dup the facet values too,
        # if the values aren't dup'd, then the values
        # from the session will get remove in the show view...
        params[param] = (params[param] || {}).dup
        params[param][url_key] = (params[param][url_key] || []).dup

        collection = params[param][url_key]
        # collection should be an array, because we link to ?f[key][]=value,
        # however, Facebook (and maybe some other PHP tools) tranform that parameters
        # into ?f[key][0]=value, which Rails interprets as a Hash.
        if collection.is_a? Hash
          Deprecation.warn(self, 'Normalizing parameters in FilterField#remove is deprecated')
          collection = collection.values
        end

        params[param][url_key] = collection - Array(value)
        params[param].delete(url_key) if params[param][url_key].empty?
        params.delete(param) if params[param].empty?

        new_state.reset(params)
      end

      # @return [Array] an array of applied filters
      def values
        params = search_state.params
        f = Array(params.dig(:f, key))
        f_inclusive = [params.dig(:f_inclusive, key)] if params.dig(:f_inclusive, key).present?
        f_missing = [{ missing: true }] if params.dig(:f, "-#{key}")&.any? { |v| v == Blacklight::Engine.config.facet_missing_param }

        f + (f_inclusive || []) + (f_missing || [])
      end
      delegate :any?, to: :values

      # @param [String,#value] a filter to remove from the url
      # @return [Boolean] whether the provided filter is currently applied/selected
      def include?(item)
        if item.respond_to?(:field) && item.field != key
          return search_state.filter(item.field).selected?(item)
        end

        value = as_url_parameter(item)
        params = search_state.params

        if value.is_a?(Array)
          (params.dig(:f_inclusive, key) || []).to_set == value.to_set
        elsif value.is_a?(Hash) && value.keys.first == :missing
          (params.dig(:f, "-#{key}") || []).include?(Blacklight::Engine.config.facet_missing_param)
        else
          (params.dig(:f, key) || []).include?(value)
        end
      end

      private

      # TODO: this code is duplicated in Blacklight::FacetsHelperBehavior
      def as_url_parameter(item)
        if item.respond_to?(:missing) && item.missing
          { missing: true }
        elsif item.respond_to? :value
          item.value
        else
          item
        end
      end
    end
  end
end
