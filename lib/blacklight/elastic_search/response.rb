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
  class Response < Blacklight::Solr::Response # rubocop:disable Metrics/ClassLength
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
      @params ||= begin
        # For Solr, request_params are the Solr parameters.
        # For ES, request_params is often the SearchBuilder.
        # We want this to return something that looks like Solr parameters
        # so that adapter-agnostic code (like FacetPaginator and many views)
        # can find things like facet.limit, facet.offset, facet.sort, etc.
        p = if @search_builder
              @search_builder.search_state.params
            else
              request_params
            end

        # We'll also merge in some Solr aliases for start/rows, which Solr's
        # Response::Params also provides.
        ActiveSupport::HashWithIndifferentAccess.new(p).merge(start: start, rows: rows)
      end
    end

    # Elasticsearch does not provide result grouping in the way Solr does.
    def grouped?
      false
    end

    # @return [Hash] options for the facet field, including limit, offset, sort, etc.
    def facet_field_aggregation_options(field_name) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      options = super
      return options unless blacklight_config

      # If the limit is the Solr default (100) and it wasn't explicitly set in the params,
      # try to get a better default from the blacklight config.
      if options[:limit] == 100 && params[:'facet.limit'].blank? && params[:"f.#{field_name}.facet.limit"].blank?
        facet_config = blacklight_config.facet_fields[field_name]

        limit = if facet_config&.limit
                  facet_config.limit == true ? blacklight_config.default_facet_limit : facet_config.limit
                else
                  blacklight_config.default_facet_limit
                end

        options[:limit] = limit if limit
      end

      # Elasticsearch terms aggregations don't support an offset, so we have to
      # determine it from the search state if it's not present in the params.
      if options[:offset].zero? && search_builder && search_builder.facet == field_name
        options[:offset] = (search_builder.search_state.facet_page - 1) * (options[:limit] || 10)
        options[:sort] ||= search_builder.search_state.facet_sort
        options[:prefix] ||= search_builder.search_state.facet_prefix
      end

      options
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
    def aggregations # rubocop:disable Metrics/CyclomaticComplexity
      @aggregations ||= begin
        result = default_aggregations

        (self['aggregations'] || {}).each do |field_name, data|
          next unless data.is_a?(Hash) && data['buckets']

          items = data['buckets'].map do |bucket|
            Blacklight::Solr::Response::Facets::FacetItem.new(value: bucket['key'], hits: bucket['doc_count'])
          end

          options = facet_field_aggregation_options(field_name)

          if options[:offset]&.positive?
            items = items[options[:offset]..] || []
          end

          # Override with the actual aggregation size from the request body.
          # facet_field_aggregation_options reads Solr-style params that do not
          # exist in an Elasticsearch request, so its limit is unreliable.
          # The FacetFieldPresenter computes: display_count = limit - 1, so
          # setting limit = requested_size gives the correct display count.
          agg_size = request_params.dig('aggs', field_name, 'terms', 'size')
          options[:limit] = agg_size if agg_size

          facet_field = Blacklight::Solr::Response::Facets::FacetField.new(field_name, items, options.merge(response: self))
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
