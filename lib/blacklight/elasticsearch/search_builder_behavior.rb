# frozen_string_literal: true

module Blacklight::Elasticsearch
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain = [
        :setup_defaults,
        :add_query,
        :empty_search_query,
        :add_facet_filter,
        :add_aggregation,
        :add_paging
        # :add_sorting_to_solr
      ]
    end

    def setup_defaults(_request)
      rows(blacklight_config.default_solr_params[:rows]) if blacklight_config.default_solr_params[:rows]
    end

    def limit_to_specific_records(request, document_ids)
      request.ids = document_ids
    end

    ##
    # Pagination parameters for selecting the previous and next documents
    # out of a result set.
    def previous_and_next_document_params(index, window = 1)
      params = blacklight_config.document_pagination_params.dup

      if params.empty?
        params[:fields] = [blacklight_config.document_model.unique_key]
        params[:_source] = false
      end

      if index > 0
        params[:start] = index - window # get one before
        params[:rows] = (2 * window) + 1 # and one after
      else
        params[:start] = 0 # there is no previous doc
        params[:rows] = 2 * window # but there should be one after
      end

      params
    end

    # Add wildcard search if no search is present (similar to q.alt in solr)
    def empty_search_query(request)
      request.match_all unless search_state.query_param.present?
    end

    def request
      Blacklight::Elasticsearch::Request.new
    end

    def add_facet_filter(request)
      search_state.filters.each do |filter|
        if filter.config.filter_query_builder
          filter_queries, = filter.config.filter_query_builder.call(self, filter, request)

          Array(filter_queries).each do |filter_query|
            request.append_filter_query(filter_query)
          end
        else
          filter.values.compact_blank.each do |value|
            value = value.first if value.is_a?(Array) && value.size == 1
            filter_query, = if value.is_a?(Array)
                              raise "Array of filter values (#{value.inspect}) is not yet supported for elasticsearch"
                            else
                              facet_value_to_fq_string(filter.config.key, value)
                            end
            request.append_filter_query filter_query
          end
        end
      end
    end

    ##
    # Take the user-entered query, and put it in the solr params,
    # including config's "search field" params for current search field.
    # also include setting spellcheck.q.
    def add_query(request)
      ##
      # Create Solr 'q' including the user-entered q, prefixed by any
      # solr LocalParams in config, using solr LocalParams syntax.
      # http://wiki.apache.org/solr/LocalParams
      ##
      return if search_state&.query_param.is_a?(Hash)

      request.append_query search_state.query_param
    end

    ##
    # Add appropriate facetting directives in, including
    # taking account of our facet paging/'more'.  This is not
    # about solr 'fq', this is about solr facet.* params.
    def add_aggregation(request)
      facet_fields_to_include_in_request.each do |field_name, facet|
        raise 'facet.json is not yet supported in the Elasticsearch configuration' if facet.json

        Blacklight.logger.warn "facet.pivot (for #{field_name}) is not yet supported in the Elasticsearch configuration" if facet.pivot
        Blacklight.logger.warn "facet.query (for #{field_name}) is not yet supported in the Elasticsearch configuration" if facet.query
        raise "facet.ex (#{facet.ex} for #{field_name}) is not yet supported in the Elasticsearch configuration" if facet.ex
        raise 'facet.solr_params is not supported in the Elasticsearch configuration' if facet.solr_params
        raise 'facet.sort is not yet supported in the Elasticsearch configuration' if facet.sort

        request.append_facet_fields facet.field

        # if facet.sort
        #   request[:"f.#{facet.field}.facet.sort"] = facet.sort
        # end

        # NOTE: Is this even supported in ES?
        # limit = facet_limit_with_pagination(field_name)
        # request[:"f.#{facet.field}.facet.limit"] = limit if limit
      end
    end

    ###
    # copy paging params from BL app over to solr, changing
    # app level per_page and page to Solr rows and start.
    def add_paging(request)
      rows(10) if rows.nil?

      request[:size] = rows
      request[:from] = start if start.nonzero?
    end

    # ###
    # # copy sorting params from BL app over to solr
    # def add_sorting_to_solr(solr_parameters)
    #   solr_parameters[:sort] = sort if sort.present?
    # end

    private

    ##
    # Convert a facet/value pair into a solr fq parameter

    def facet_value_to_fq_string(facet_field, value, use_local_params: true)
      facet_config = blacklight_config.facet_fields[facet_field]

      index_field = facet_config.field if facet_config && !facet_config.query
      index_field ||= facet_field

      raise "facet value not found, #{value}" if facet_config&.query && !facet_config.query[value]

      { 'term' => { index_field => convert_to_term_value(value) } }
    end

    def convert_to_term_value(value)
      case value
      when DateTime, Time
        value.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      when Date
        value.to_time(:local).strftime("%Y-%m-%dT%H:%M:%SZ")
      else
        value.to_s
      end
    end

    # TODO: Identical to method in Solr search builder. Perhaps move to blacklight_config?
    def facet_fields_to_include_in_request
      blacklight_config.facet_fields.select do |_field_name, facet|
        facet.include_in_request || (facet.include_in_request.nil? && blacklight_config.add_facet_fields_to_solr_request)
      end
    end
  end
end
