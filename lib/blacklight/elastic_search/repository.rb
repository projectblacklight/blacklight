# frozen_string_literal: true

module Blacklight::ElasticSearch
  # Repository adapter for an Elasticsearch (or API-compatible OpenSearch)
  # cluster.
  #
  # The connection is built from `config/blacklight.yml`. Supported keys:
  #   * `url`   - the cluster URL, e.g. http://localhost:9200
  #   * `index` - the index (or alias) to search against
  #   * `client_options` - a hash passed through to the client constructor
  #   * `client_class`   - a fully-qualified client class name to use instead
  #                        of auto-detecting Elasticsearch::Client / OpenSearch::Client
  class Repository < Blacklight::AbstractRepository # rubocop:disable Metrics/ClassLength
    # The Blacklight response model that understands Elasticsearch responses.
    def self.response_model
      Blacklight::ElasticSearch::Response
    end

    # The facet paginator used for Elasticsearch facet values.
    def self.facet_paginator_class
      Blacklight::ElasticSearch::FacetPaginator
    end

    # The SearchBuilder behavior mixed in to the application's SearchBuilder.
    def self.search_builder_behavior
      Blacklight::ElasticSearch::SearchBuilderBehavior
    end

    # The document mixin included in the application's document model.
    def self.document_mixin
      Blacklight::ElasticSearch::Document
    end

    # Find a single document by its id.
    # @param [String] id document's unique key value
    # @param [Hash] _params additional query parameters (unused)
    # @return [Blacklight::ElasticSearch::Response]
    def find(id, _params = {})
      response = search_request(query: { ids: { values: Array(id) } }, size: Array(id).size)
      result = build_response(response, {})
      raise Blacklight::Exceptions::RecordNotFound if result.documents.empty?

      result
    end

    # Find multiple documents by id (or any other query).
    # @param [Hash, Blacklight::SearchBuilder] params query parameters
    def find_many(params)
      search(params: params)
    end

    # Execute a search query against Elasticsearch.
    # @param [Hash, Blacklight::SearchBuilder] params the request body (Query DSL)
    # @return [Blacklight::ElasticSearch::Response]
    def search(pos_params = nil, params: nil, **kwargs)
      if pos_params
        Blacklight.deprecation.warn("Passing positional arguments to search() is deprecated. Use the params kwarg instead.")
      end

      request_params = params || pos_params || kwargs
      body = body_for(request_params)

      response = search_request(body)
      build_response(response, request_params)
    end

    # @return [Boolean] true if the cluster is reachable
    def ping?
      !!connection.ping
    end
    alias ping ping?

    # Query the fields that exist in the index from its mapping.
    # @return [Hash]
    def reflect_fields
      mapping = connection.indices.get_mapping(index: index_name).to_h
      properties = mapping.values.first&.dig('mappings', 'properties') || {}
      properties.transform_values(&:to_h)
    rescue StandardError => e
      Blacklight.logger&.warn("Unable to reflect fields from Elasticsearch: #{e.inspect}")
      {}
    end

    # Suggestions ("autocomplete") are not supported by this adapter.
    def suggestions(_request_params)
      Blacklight.logger&.debug("Suggestions are not supported by the Elasticsearch adapter")
      Blacklight::Suggest::Response.new({}, {}, nil, nil)
    end

    ##
    # Indexing helpers used by the `blacklight:index:seed` rake task.
    ##

    # Add (index) one or more documents.
    # @param [Array<Hash>, Hash] documents
    def add(documents, **)
      docs = Array.wrap(documents)
      return if docs.empty?

      operations = docs.flat_map do |doc|
        doc = doc.to_h if doc.respond_to?(:to_h)
        id = doc[unique_key.to_s] || doc[unique_key.to_sym]
        id = Array(id).first
        [{ index: { _index: index_name, _id: id } }, doc]
      end

      connection.bulk(body: operations)
    end

    # Refresh the index so newly added documents are searchable. This is the
    # Elasticsearch analog to Solr's commit.
    def commit(**)
      connection.indices.refresh(index: index_name)
    end

    # Create the search index if it does not already exist.
    #
    # The default mapping understands Blacklight's Solr field-naming
    # conventions: fields ending in a text suffix (e.g. `_tsim`, `_tesim`) are
    # mapped as analyzed `text` for full-text search, while all other string
    # fields (e.g. `_ssim`, `_si`, `format`, `id`) are mapped as `keyword` so
    # they can be used for exact-match filtering, sorting, and aggregations.
    #
    # Override the mapping by setting `blacklight_config.elasticsearch_index_settings`.
    #
    # @return [Boolean] true if the index was created, false if it already existed
    def create_index!
      connection.indices.create(index: index_name, body: index_settings)
      true
    rescue StandardError => e
      # An already-existing index is not an error. Re-raise anything else.
      raise unless index_already_exists?(e)

      false
    end

    # @return [String] the configured index name
    def index_name
      connection_config[:index] || blacklight_config&.elasticsearch_index || 'blacklight'
    end

    private

    # @return [Boolean] whether the error indicates the index already exists
    def index_already_exists?(error)
      message = error.respond_to?(:message) ? error.message : error.to_s
      message.include?('resource_already_exists_exception') || message.include?('index_already_exists_exception')
    end

    def search_request(body)
      response = connection.search(index: index_name, body: body)
      response.respond_to?(:to_h) ? response.to_h : response
    rescue Errno::ECONNREFUSED => e
      raise Blacklight::Exceptions::ECONNREFUSED, "Unable to connect to Elasticsearch instance using #{connection.inspect}: #{e.inspect}"
    rescue StandardError => e
      raise Blacklight::Exceptions::InvalidRequest, e.message
    end

    def build_response(response, request_params)
      benchmark("Elasticsearch fetch", level: :debug) do
        result = blacklight_config.response_model.new(
          response,
          request_params,
          document_model: blacklight_config.document_model,
          blacklight_config: blacklight_config
        )
        Blacklight.logger&.debug("Elasticsearch query: #{index_name} #{body_for(request_params).inspect}")
        result
      end
    end

    def body_for(request_params)
      body = request_params.respond_to?(:to_hash) ? request_params.to_hash : (request_params || {})
      sanitize_body(body)
    end

    # Blacklight (and callers like SearchService#previous_and_next_document_params)
    # may merge Solr-style parameters into the request. Translate the ones that
    # have an Elasticsearch equivalent and drop the rest so the Query DSL body
    # stays valid.
    def sanitize_body(body)
      body = body.dup

      fl = delete_param(body, :fl)
      body[:_source] ||= Array(fl) if fl

      body.delete(:aggs) if delete_param(body, :facet) == false

      start = delete_param(body, :start)
      body[:from] ||= start.to_i if start

      rows = delete_param(body, :rows)
      body[:size] ||= rows.to_i if rows

      # Solr-only parameters that have no Elasticsearch equivalent.
      delete_param(body, :qt)
      delete_param(body, :spellcheck)

      body
    end

    # Delete a key that may be present as either a Symbol or a String.
    # @return the deleted value, or nil
    def delete_param(body, key)
      value = body.delete(key)
      value.nil? ? body.delete(key.to_s) : value
    end

    def unique_key
      (blacklight_config&.document_model || ::SolrDocument).unique_key
    end

    def build_connection
      options = (connection_config[:client_options] || {}).symbolize_keys
      options[:url] ||= connection_config[:url] if connection_config[:url]

      client_class.new(**options)
    end

    def client_class
      if connection_config[:client_class]
        connection_config[:client_class].to_s.constantize
      elsif defined?(::Elasticsearch::Client)
        ::Elasticsearch::Client
      elsif defined?(::OpenSearch::Client)
        ::OpenSearch::Client
      else
        begin
          require 'elasticsearch'
          ::Elasticsearch::Client
        rescue LoadError
          require 'opensearch'
          ::OpenSearch::Client
        end
      end
    end

    def index_settings
      blacklight_config&.elasticsearch_index_settings || default_index_settings
    end

    def default_index_settings
      {
        mappings: {
          dynamic_templates: [
            # Blacklight text fields (e.g. title_tsim, author_tsim) -> analyzed text
            {
              text_fields: {
                match_pattern: 'regex',
                match: '.*_t[a-z]*$',
                mapping: { type: 'text' }
              }
            },
            # All other string fields (e.g. format, *_ssim, *_si, id) -> keyword,
            # so they support filtering, sorting, and aggregations. Long values
            # (e.g. stored MARC) are kept in _source but not indexed as terms.
            {
              string_fields: {
                match_mapping_type: 'string',
                mapping: { type: 'keyword', ignore_above: 8192 }
              }
            }
          ]
        }
      }
    end
  end
end
