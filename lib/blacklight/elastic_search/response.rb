# frozen_string_literal: true

module Blacklight::ElasticSearch
  # Normalizes an Elasticsearch search response into the interface the rest of
  # Blacklight expects from Blacklight::Solr::Response, so views, presenters, and
  # components work unchanged regardless of the configured adapter.
  #
  # It subclasses Blacklight::Solr::Response so that code (and specs) that check
  # for `Blacklight::Solr::Response` continue to work; the Solr-shaped accessors
  # are overridden to read Elasticsearch's response shape.
  #
  # Solr-only concepts (spelling suggestions, result grouping, and
  # more-like-this) are represented with null/empty implementations.
  class Response < Blacklight::Solr::Response
    # A stand-in for Blacklight::Solr::Response::Spelling, which Elasticsearch
    # does not provide an equivalent of.
    class NullSpelling
      def words
        []
      end

      def collation
        nil
      end
    end

    # @param [Hash] data the raw Elasticsearch response
    # @param [Hash, Blacklight::SearchBuilder] request_params a SearchBuilder or a Hash of parameters
    def initialize(data, request_params, options = {})
      data = data.to_hash if data.respond_to?(:to_hash)
      super
    end

    def hits
      self['hits'] || {}
    end

    def documents
      @documents ||= (hits['hits'] || []).map do |hit|
        source = (hit['_source'] || {}).dup
        source[unique_key] ||= hit['_id']
        source['_highlighting'] = hit['highlight'] if hit['highlight'].present?

        document_factory.build(source, self, options)
      end
    end
    alias docs documents

    # The total number of matching documents.
    def total
      raw = hits['total']

      if raw.is_a?(Hash)
        raw['value'].to_i
      else
        raw.to_i
      end
    end

    def start
      search_builder&.start || request_params[:from].to_i
    end

    def rows
      search_builder&.rows || request_params[:size]&.to_i || documents.length
    end

    def sort
      search_builder&.sort
    end

    def empty?
      total.zero?
    end

    # The request parameters, augmented with Solr-style `start`/`rows` aliases so
    # that adapter-agnostic callers (e.g. `response.params[:start]`) keep working.
    def params
      @params ||= request_params.merge(start: start, rows: rows)
    end

    # Elasticsearch does not provide result grouping in the way Solr does.
    def grouped?
      false
    end

    # @return [NullSpelling] spelling suggestions are not supported
    def spelling
      @spelling ||= NullSpelling.new
    end

    # More-like-this is not supported by this adapter.
    def more_like(_document)
      []
    end

    # Convert Elasticsearch aggregations into the hash of
    # Blacklight::Solr::Response::Facets::FacetField objects that Blacklight's
    # facet display expects.
    def aggregations
      @aggregations ||= begin
        result = default_aggregations

        (self['aggregations'] || {}).each do |field_name, data|
          next unless data.is_a?(Hash) && data['buckets']

          items = data['buckets'].map do |bucket|
            Blacklight::Solr::Response::Facets::FacetItem.new(value: bucket['key'], hits: bucket['doc_count'])
          end

          facet_field = Blacklight::Solr::Response::Facets::FacetField.new(field_name, items, response: self)
          result[field_name] = facet_field

          next unless blacklight_config

          blacklight_config.facet_fields.select { |_k, v| v.field == field_name }.each_key do |key|
            result[key] = facet_field
          end
        end

        result
      end
    end

    private

    def unique_key
      (blacklight_config&.document_model || ::SolrDocument).unique_key
    end

    # @return [HashWithIndifferentAccess] hash with a null-object default for missing facet fields
    def default_aggregations
      h = Hash.new do |_hash, key|
        Blacklight::Solr::Response::Facets::NullFacetField.new(key, response: self)
      end
      h.with_indifferent_access
    end
  end
end
