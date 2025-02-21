# frozen_string_literal: true

module Blacklight
  class SearchState
    # Modeling access to filter query parameters
    class FilterField
      MISSING = { missing: true }.freeze

      # @!attribute config
      #   @return [Blacklight::Configuration::FacetField]
      # @!attribute search_state
      #   @return [Blacklight::SearchState]
      # @!attribute param
      #   @return [String,Symbol]
      # @!attribute inclusive_param
      #   @return [String,Symbol]
      attr_reader :config, :search_state, :filters_key, :inclusive_filters_key

      # @return [String,Symbol]
      delegate :key, to: :config

      # @param [Blacklight::Configuration::FacetField] config
      # @param [Blacklight::SearchState] search_state
      def initialize(config, search_state)
        @config = config
        @search_state = search_state
        @filters_key = :f
        @inclusive_filters_key = :f_inclusive
      end

      # @param [String,#value] item a filter item to add to the url
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

        return new_state.filter(item.field).add(item) if item.respond_to?(:field) && item.field != key

        url_key = key
        params = new_state.params
        param = filters_key
        value = as_url_parameter(item)

        if value == Blacklight::SearchState::FilterField::MISSING
          url_key = "-#{key}"
          value = Blacklight::Engine.config.blacklight.facet_missing_param
        end

        param = inclusive_filters_key if value.is_a?(Array)

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

      # @param [String,#value] item a filter to remove from the url
      # @return [Blacklight::SearchState] new state
      def remove(item)
        new_state = search_state.reset_search

        return new_state.filter(item.field).remove(item) if item.respond_to?(:field) && item.field != key

        url_key = config.key
        params = new_state.params

        param = filters_key
        value = as_url_parameter(item)

        if value == Blacklight::SearchState::FilterField::MISSING
          url_key = "-#{key}"
          value = Blacklight::Engine.config.blacklight.facet_missing_param
        end

        param = inclusive_filters_key if value.is_a?(Array)

        # need to dup the facet values too,
        # if the values aren't dup'd, then the values
        # from the session will get remove in the show view...
        params[param] = (params[param] || {}).dup
        params[param][url_key] = (params[param][url_key] || []).dup

        collection = params[param][url_key]

        params[param][url_key] = collection - Array(value)
        params[param].delete(url_key) if params[param][url_key].empty?
        params.delete(param) if params[param].empty?

        new_state.reset(params)
      end

      # @return [Array] an array of applied filters
      def values(except: [])
        params = search_state.params
        return [] if params.blank?

        f = except.include?(:filters) ? [] : [params.dig(filters_key, key)].flatten.compact
        f_inclusive = [params.dig(:f_inclusive, key)] unless params.dig(inclusive_filters_key, key).blank? || except.include?(:inclusive_filters)
        f_missing = [Blacklight::SearchState::FilterField::MISSING] if params.dig(filters_key, "-#{key}")&.any? { |v| v == Blacklight::Engine.config.blacklight.facet_missing_param }
        f_missing = [] if except.include?(:missing)

        f + (f_inclusive || []) + (f_missing || [])
      end
      delegate :any?, to: :values

      # Appease rubocop rules by implementing #each_value
      def each_value(except: [], &block)
        values(except: except).each(&block)
      end

      # @param [String,#value] item a filter to remove from the url
      # @return [Boolean] whether the provided filter is currently applied/selected
      def include?(item)
        return search_state.filter(item.field).selected?(item) if item.respond_to?(:field) && item.field != key

        value = as_url_parameter(item)
        params = search_state.params

        case value
        when Array
          (params.dig(inclusive_filters_key, key) || []).to_set == value.to_set
        when Blacklight::SearchState::FilterField::MISSING
          (params.dig(filters_key, "-#{key}") || []).include?(Blacklight::Engine.config.blacklight.facet_missing_param)
        else
          (params.dig(filters_key, key) || []).include?(value)
        end
      end

      def permitted_params
        if config.pivot
          {
            filters_key => config.pivot.each_with_object({}) { |key, filter| filter.merge!(key => [], "-#{key}" => []) },
            inclusive_filters_key => config.pivot.each_with_object({}) { |key, filter| filter.merge!(key => []) }
          }
        else
          {
            filters_key => { config.key => [], "-#{config.key}" => [] },
            inclusive_filters_key => { config.key => [] }
          }
        end
      end

      private

      # TODO: this code is duplicated in Blacklight::FacetsHelperBehavior
      def as_url_parameter(item)
        if item.respond_to?(:missing) && item.missing
          Blacklight::SearchState::FilterField::MISSING
        elsif item.respond_to? :value
          item.value
        else
          item
        end
      end
    end
  end
end
