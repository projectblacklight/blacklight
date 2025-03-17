# frozen_string_literal: true

# class Blacklight::Elasticsearch::InvalidParameter < ArgumentError; end

class Blacklight::Elasticsearch::Request < ActiveSupport::HashWithIndifferentAccess
  # This is similar to qf in Solr
  cattr_accessor :query_fields, default: %w[ id
                                             full_title_tsim
                                             short_title_tsim
                                             alternative_title_tsim
                                             active_fedora_model_ssi
                                             title_tsim
                                             author_tsim
                                             subject_tsim
                                             all_text_timv]
  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super
    end
  end

  # See https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html
  def match_all
    must['match_all'] = {}
  end

  # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
  def append_filter_query(filter_query)
    bool['filter'] = filter_query
  end

  # See https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-combined-fields-query.html
  def append_query(query)
    return if query.nil?

    must['combined_fields'] = {
      'query' => query,
      'fields' => query_fields,
      'operator' => 'or'
    }
  end

  def append_facet_fields(value)
    self['aggs'] ||= {}
    self['aggs']["bl-#{value}"] = { terms: { field: value } }
  end

  private

  def bool
    self['query'] ||= {}
    self['query']['bool'] ||= {}
  end

  def must
    bool['must'] ||= {}
  end
end
