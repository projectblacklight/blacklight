# frozen_string_literal: true

module Blacklight::ElasticSearch
  # Pagination for facet values returned by Elasticsearch terms aggregations.
  #
  # Like Solr, Elasticsearch terms aggregations don't return a total count of
  # distinct values, so we request `limit + 1` values to detect whether more
  # values are available. We subclass the Solr paginator so that adapter-agnostic
  # callers (and specs) that check for `Blacklight::Solr::FacetPaginator` work.
  class FacetPaginator < Blacklight::Solr::FacetPaginator
  end
end
