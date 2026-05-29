# frozen_string_literal: true

module Blacklight::ElasticSearch
  # Accumulates an Elasticsearch Query DSL request body as the SearchBuilder
  # processor chain runs. This is the Elasticsearch analog to
  # Blacklight::Solr::Request.
  #
  # The resulting hash is sent to Elasticsearch as the search request `body`.
  class Request < Hash
    def initialize(constructor = {})
      super()
      merge!(constructor) if constructor.is_a?(Hash)
    end

    # The boolean query container, lazily initialized.
    # @return [Hash]
    def bool
      self[:query] ||= {}
      self[:query][:bool] ||= { must: [], filter: [], must_not: [], should: [] }
    end

    # Add a query clause that documents must match (and that contributes to scoring)
    def append_query(query)
      return if query.blank?

      bool[:must] << query
    end

    # Add a non-scoring filter clause that documents must match
    def append_filter_query(query)
      return if query.blank?

      bool[:filter] << query
    end

    # Add a clause that documents must not match
    def append_must_not(query)
      return if query.blank?

      bool[:must_not] << query
    end

    # Add a terms (or other) aggregation used to compute facet values
    def append_aggregation(name, aggregation)
      self[:aggs] ||= {}
      self[:aggs][name.to_s] = aggregation
    end

    # Add a field to highlight in the response
    def append_highlight_field(field)
      self[:highlight] ||= { fields: {} }
      self[:highlight][:fields][field.to_s] ||= {}
    end
  end
end
