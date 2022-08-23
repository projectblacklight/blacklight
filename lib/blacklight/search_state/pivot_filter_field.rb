# frozen_string_literal: true

module Blacklight
  class SearchState
    # Modeling access to filter query parameters
    class PivotFilterField < FilterField
      STOP_VALUE = [:stop].freeze

      # @return [Array]
      delegate :pivot, to: :config

      # @param [String,#value] item a filter item to add to the url
      # @return [Blacklight::SearchState] new state
      def add(item)
        item = wrap_item(item)
        new_state = search_state.reset_search
        return new_state if include?(item)

        pivot_values = pivot_fq(item).merge(pivot[0].to_sym => as_url_parameter(item))
        pivot_values.inject(new_state) do |memo_state, entry|
          url_key, value = entry
          field_facade = FilterField.new(null_field(url_key), memo_state)
          next memo_state if value.nil? || field_facade.include?(value)

          field_facade.add(value)
        end
      end

      # @param [String,#value] item a filter to remove from the url
      # @return [Blacklight::SearchState] new state
      def remove(item)
        item = wrap_item(item)
        new_state = search_state.reset_search
        pivot_values = pivot_fq(item).merge(pivot[0].to_sym => as_url_parameter(item))
        pivot_values.inject(new_state) do |memo_state, entry|
          url_key, value = entry
          next memo_state if value.nil?

          FilterField.new(null_field(url_key), memo_state).remove(value)
        end
      end

      # Matrix the values of the pivoted fields
      # @return [Array] an array of applied filters
      # rubocop:disable Lint/UnusedMethodArgument
      def values(except: [])
        return nil unless pivot.is_a?(Array) && pivot.present?

        params = search_state.params
        # values should have at most one terminal blank pivot
        pivot_values = pivot.map { |k| Array(params.dig(:f, k)) || STOP_VALUE }
        pivot_values = pivot_values[0..(pivot_values.index(STOP_VALUE) || -1)]
        # put an explicit nil in for the matrix
        pivot_values[-1] = [nil] if pivot_values.last == STOP_VALUE
        top_level_values = pivot_values.shift
        return [] if top_level_values.first.blank?

        pivot_values.each { |pivot_value| pivot_value[0] ||= nil }
        matrix_values = top_level_values.product(*pivot_values)
        matrix_values.map do |vals|
          PivotValue.new(value: vals.shift, fq: (pivot[1..-1]).map(&:to_sym).zip(vals).to_h)
        end
      end
      # rubocop:enable Lint/UnusedMethodArgument

      # @param [String, #value #fq] item a filter may represent in the url
      # @return [Boolean] whether the provided filter is currently applied/selected
      def include?(item)
        return false unless pivot.is_a?(Array) && pivot.present?

        params = search_state.params
        item = wrap_item(item)
        pivot_values = pivot_fq(item).merge(pivot[0].to_sym => as_url_parameter(item))
        pivot_values.inject(true) do |m, entry|
          k, v = entry
          m && params.dig(:f, k)&.include?(as_url_parameter(v))
        end
      end

      class PivotValue
        attr_accessor :value, :fq

        delegate :blank?, :present?, to: :value
        alias empty? blank?

        def initialize(value: nil, fq: {}, **_args) # rubocop:disable Naming/MethodParameterName
          @value = value
          @fq = fq
        end
      end

      class QueryBuilder
        # @return [Array] filter_query, subqueries
        def self.call(search_builder, filter, solr_parameters)
          existing = solr_parameters['fq']&.dup || []
          queries = []
          filter.values.reject(&:blank?).each do |value|
            queries << search_builder.send(:facet_value_to_fq_string, filter.pivot.first, value.value)
            value.fq.each do |entry|
              k, v = entry
              queries << search_builder.send(:facet_value_to_fq_string, k, v) if v
            end
            queries.uniq!
          end
          [(queries - existing)]
        end
      end

      private

      def null_field(key)
        Blacklight::Configuration::NullField.new(key: key)
      end

      def pivot_fq(item = nil)
        fq_keys = pivot[1..-1].map(&:to_sym)
        null_values = fq_keys.map { |k| [k, nil] }.to_h
        return null_values unless item.respond_to?(:fq)

        item_fq = item.fq.to_h.symbolize_keys.slice(*fq_keys)
        null_values.merge item_fq
      end

      def wrap_item(item)
        item = invert_item(item) if item.respond_to?(:field) && item.field.to_sym != pivot.first.to_sym
        return item if item.respond_to? :value
        return PivotValue.new(**item) if item.is_a? Hash

        PivotValue.new(value: item, fq: pivot_fq)
      end

      # the parsed Blacklight::Solr::Response::Facets::FacetItem objects are inverted -
      # the subordinate value is at the top, and the other values are in fq - to permit
      # easier value labeling in the UI. To manage the search links, they need to be
      # reinverted.
      def invert_item(item)
        item_fq = item.fq.symbolize_keys
        item_value = item_fq.delete(pivot[0].to_sym)
        item_fq = item_fq.merge(item.field.to_sym => item.value).slice(*pivot.map(&:to_sym))
        PivotValue.new(value: item_value, fq: item_fq)
      end
    end
  end
end
