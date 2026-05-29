# frozen_string_literal: true

module Blacklight::ElasticSearch
  # Translates Blacklight request parameters into an Elasticsearch Query DSL
  # request body. This is the Elasticsearch analog to
  # Blacklight::Solr::SearchBuilderBehavior.
  #
  # Features that Elasticsearch does not provide in the same way Solr does
  # (spellcheck, result grouping, pivot/query facets, and the Solr JSON Query
  # DSL advanced search) are intentionally omitted from the processor chain.
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain = [
        :add_query_to_request,
        :add_filters_to_request,
        :add_facetting_to_request,
        :add_paging_to_request,
        :add_sorting_to_request,
        :add_highlighting_to_request,
        :add_source_fields_to_request,
        :add_additional_filters_to_request,
        :add_facet_paging_to_request
      ]
    end

    # Add the user-entered query to the request as a full-text query.
    def add_query_to_request(request)
      query = search_state.query_param

      return if query.blank? || query.is_a?(Hash)

      fields = query_fields

      request.append_query(
        if fields.present?
          { multi_match: { query: query, fields: fields, type: 'best_fields', operator: 'and' } }
        else
          { simple_query_string: { query: query, default_operator: 'and' } }
        end
      )
    end

    # Map the applied facet filters (Blacklight's `f` parameter) to
    # Elasticsearch term filters.
    def add_filters_to_request(request)
      search_state.filters.each do |filter|
        field = filter_field_name(filter)
        values = Array(filter.values).compact_blank

        if values.delete(Blacklight::SearchState::FilterField::MISSING)
          request.append_must_not(exists: { field: field })
        end

        next if values.empty?

        request.append_filter_query(terms: { field => values })
      end
    end

    # Build terms aggregations for each configured facet field. Pivot and query
    # facets are not supported by this adapter and are skipped.
    def add_facetting_to_request(request)
      facet_fields_to_include_in_request.each do |field_name, facet_config|
        next if facet.present? && facet == field_name

        if facet_config.pivot || facet_config.query
          Blacklight.logger&.debug("Skipping facet '#{field_name}': pivot and query facets are not supported by the Elasticsearch adapter")
          next
        end

        size = facet_limit_with_pagination(field_name) || blacklight_config.default_facet_limit
        order = if facet_config.sort == 'index'
                  { '_key' => 'asc' }
                else
                  [{ '_count' => 'desc' }, { '_key' => 'asc' }]
                end

        request.append_aggregation(field_name, terms: { field: facet_config.field, size: size, order: order })
      end
    end

    # Translate Blacklight paging into Elasticsearch from/size.
    def add_paging_to_request(request)
      request[:size] = rows
      request[:from] = start if start.nonzero?
      # Ensure the reported hit total is exact (Elasticsearch otherwise caps the
      # tracked total at 10,000), so pagination shows the correct number of pages.
      request[:track_total_hits] = true
    end

    # Translate the Solr-style sort string (e.g. "score desc, title_si asc")
    # into the Elasticsearch sort syntax.
    def add_sorting_to_request(request)
      return if sort.blank?

      request[:sort] = sort.split(',').filter_map do |clause|
        field, direction = clause.strip.split(/\s+/)
        next if field.blank?

        field = '_score' if field == 'score'
        { field => { order: direction.presence || 'asc' } }
      end
    end

    # Request highlight snippets for index fields configured with `highlight: true`.
    def add_highlighting_to_request(request)
      blacklight_config.index_fields.each_value do |field|
        request.append_highlight_field(field.field) if field.highlight
      end
    end

    # Limit the returned _source fields when configured to do so. By default we
    # return the full source document.
    def add_source_fields_to_request(request)
      fields = source_fields
      request[:_source] = fields if fields.present?
    end

    # Support SearchBuilder#where, which is used to fetch documents by id.
    def add_additional_filters_to_request(request, additional_filters = nil)
      filters = additional_filters || @additional_filters

      return if filters.blank?

      if filters.values.any?(&:blank?)
        request.append_filter_query(ids: { values: [] })
        return
      end

      filters.each do |field, values|
        if field.to_s == blacklight_config.document_model.unique_key
          request.append_filter_query(ids: { values: Array(values) })
        else
          request.append_filter_query(terms: { field => Array(values) })
        end
      end
    end

    # Handle facet-specific pagination parameters (e.g. for the facet modal)
    def add_facet_paging_to_request(request)
      return if facet.blank?

      # We don't need any documents when we're only fetching facet values
      request[:size] = 0

      facet_config = blacklight_config.facet_fields[facet]
      return if facet_config.blank?

      limit = facet_limit_for(facet) || blacklight_config.default_facet_limit
      page = search_state.facet_page
      sort = search_state.facet_sort
      prefix = search_state.facet_prefix
      offset = (page - 1) * limit

      # Since Elasticsearch's terms aggregation does not support an offset, we
      # request enough items to cover the offset and the requested limit (plus
      # one to detect whether more values are available).
      size = offset + limit + 1
      order = if sort == 'index'
                { '_key' => 'asc' }
              else
                [{ '_count' => 'desc' }, { '_key' => 'asc' }]
              end

      # Elasticsearch uses the `include` parameter for prefix filtering and
      # suggestions, which expects a regular expression.
      include_regex = if facet_suggestion_query.present? && prefix.present?
                        "#{lucene_case_insensitive_regex(prefix)}.*#{lucene_case_insensitive_regex(facet_suggestion_query)}.*"
                      elsif facet_suggestion_query.present?
                        ".*#{lucene_case_insensitive_regex(facet_suggestion_query)}.*"
                      elsif prefix.present?
                        "#{lucene_case_insensitive_regex(prefix)}.*"
                      end

      agg = { field: facet_config.field, size: size, order: order, include: include_regex }.compact
      request.append_aggregation(facet, terms: agg)
    end

    private

    # @return [Blacklight::ElasticSearch::Request]
    def request
      Blacklight::ElasticSearch::Request.new
    end

    # Override the base SearchBuilder default so that `for_previous_and_next_documents`
    # merges an Elasticsearch-appropriate `_source` restriction instead of a
    # Solr-style `fl` field-list parameter.
    def default_document_pagination_params
      { _source: Array(blacklight_config.document_model.unique_key) }
    end

    # Convert a string into a case-insensitive Lucene regular expression
    # by replacing each letter with a character class (e.g. "a" -> "[aA]").
    def lucene_case_insensitive_regex(str)
      str.chars.map do |char|
        if char =~ /[[:alpha:]]/
          "[#{char.downcase}#{char.upcase}]"
        else
          Regexp.escape(char)
        end
      end.join
    end

    # The fields a full-text query should target. When a search field is
    # selected, its `elastic_query_fields` (configured in the controller) scope
    # the query; otherwise the configuration-wide default is used (and when that
    # is also unset, a simple_query_string across all fields is used).
    # @return [Array<String>, nil]
    def query_fields
      search_field&.elastic_query_fields || blacklight_config.elasticsearch_query_fields
    end

    # @return [Array<String>, nil]
    def source_fields
      blacklight_config.elasticsearch_source_fields
    end

    def filter_field_name(filter)
      filter.config&.field || filter.key
    end

    def facet_fields_to_include_in_request
      blacklight_config.facet_fields.select do |_field_name, facet|
        facet.include_in_request || (facet.include_in_request.nil? && blacklight_config.add_facet_fields_to_solr_request)
      end
    end

    # Look up the configured limit for a facet field. Mirrors the Solr behavior.
    def facet_limit_for(facet_field)
      facet = blacklight_config.facet_fields[facet_field]
      return if facet.blank?

      return unless facet.limit

      facet.limit == true ? blacklight_config.default_facet_limit : facet.limit
    end

    # Request one more than the display limit so the facet paginator can detect
    # whether more values are available.
    def facet_limit_with_pagination(field_name)
      limit = facet_limit_for(field_name)

      return if limit.nil?

      limit.positive? ? limit + 1 : limit
    end
  end
end
