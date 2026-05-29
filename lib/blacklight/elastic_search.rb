# frozen_string_literal: true

module Blacklight
  # Adapter for using an Elasticsearch (or API-compatible OpenSearch) cluster as
  # the search index backing a Blacklight application.
  #
  # The adapter is selected by setting `adapter: elasticsearch` in
  # `config/blacklight.yml`. Some Solr-specific features (spellcheck/"did you
  # mean", result grouping, pivot/query facets, more-like-this, and the Solr
  # JSON Query DSL advanced search) are not provided by Elasticsearch and are
  # automatically disabled when this adapter is in use.
  module ElasticSearch
  end
end
