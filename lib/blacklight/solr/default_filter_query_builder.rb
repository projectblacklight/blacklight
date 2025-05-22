# frozen_string_literal: true

module Blacklight::Solr
  class DefaultFilterQueryBuilder < AbstractFilterQueryBuilder
    def call(filter, _solr_parameters)
      filter_queries = []
      all_subqueries = {}
      filter.values.compact_blank.each do |value|
        filter_query, subqueries = if value.is_a?(Array)
                                     facet_inclusive_value_to_fq_string(filter.key, value.compact_blank)
                                   else
                                     facet_value_to_fq_string(filter.config.key, value)
                                   end
        filter_queries << filter_query
        all_subqueries.merge!(subqueries) if subqueries
      end
      [filter_queries, all_subqueries]
    end
  end
end
