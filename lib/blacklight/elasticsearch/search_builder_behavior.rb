# frozen_string_literal: true

module Blacklight::Elasticsearch
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain = [
        :add_query,
        :empty_search_query,
        :add_facet_filter,
        :add_aggregation
        # :default_solr_parameters, :add_search_field_default_parameters,
        # :add_solr_fields_to_query, :add_paging_to_solr,
        # :add_sorting_to_solr, :add_group_config_to_solr,
        # :add_facet_paging_to_solr, :add_facet_suggestion_parameters,
        # :add_adv_search_clauses,
        # :add_additional_filters
      ]
    end

    ##
    # Pagination parameters for selecting the previous and next documents
    # out of a result set.
    def previous_and_next_document_params(index, window = 1)
      params = blacklight_config.document_pagination_params.dup

      if params.empty?
        params[:fields] = [blacklight_config.document_model.unique_key]
      end

      if index > 0
        params[:start] = index - window # get one before
        params[:rows] = (2 * window) + 1 # and one after
      else
        params[:start] = 0 # there is no previous doc
        params[:rows] = 2 * window # but there should be one after
      end

      # solr_params[:facet] = false
      params
    end

    # Add wildcard search if no search is present (similar to q.alt in solr)
    def empty_search_query(request)
      request.match_all
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
            filter_query, = if value.is_a?(Array)
                              facet_inclusive_value_to_fq_string(filter.key, value.compact_blank)
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

    # def add_solr_facet_json_params(solr_parameters, field_name, facet, **additional_parameters)
    #   solr_parameters[:json] ||= { facet: {} }
    #   solr_parameters[:json][:facet] ||= {}

    #   field_config = facet.json.respond_to?(:reverse_merge) ? facet.json : {}

    #   field_config = field_config.reverse_merge(
    #     type: 'terms',
    #     field: facet.field,
    #     limit: facet_limit_with_pagination(field_name)
    #   ).merge(additional_parameters)

    #   solr_parameters[:json][:facet][field_name] = field_config.compact_blank
    # end

    ##
    # Add appropriate facetting directives in, including
    # taking account of our facet paging/'more'.  This is not
    # about solr 'fq', this is about solr facet.* params.
    def add_aggregation(request)
      facet_fields_to_include_in_request.each do |field_name, facet|
        # solr_parameters[:facet] ||= true
        if facet.json
          raise 'not implemented'
          add_solr_facet_json_params(request, field_name, facet)
          next
        end

        # TODO: support pivot, query, ex
        # if facet.pivot
        #   raise 'not implemented'
        #   request.append_facet_pivot with_ex_local_param(facet.ex, facet.pivot.join(","))
        # elsif facet.query
        #   raise 'not implemented'
        #   request.append_facet_query(facet.query.values.map { |x| with_ex_local_param(facet.ex, x[:fq]) })
        # # TODO: elsif facet.ex
        # else
        request.append_facet_fields facet.field
        # end

        if facet.sort
          request[:"f.#{facet.field}.facet.sort"] = facet.sort
        end

        next unless facet.solr_params

        facet.solr_params.each do |k, v|
          request[:"f.#{facet.field}.#{k}"] = v
        end

        # NOTE: Is this even supported in ES?
        # limit = facet_limit_with_pagination(field_name)
        # request[:"f.#{facet.field}.facet.limit"] = limit if limit
      end
    end

    # def add_solr_fields_to_query solr_parameters
    #   blacklight_config.show_fields.select(&method(:should_add_field_to_request?)).each_value do |field|
    #     next unless field.solr_params

    #     field.solr_params.each do |k, v|
    #       solr_parameters[:"f.#{field.field}.#{k}"] = v
    #     end
    #   end

    #   blacklight_config.index_fields.select(&method(:should_add_field_to_request?)).each_value do |field|
    #     if field.highlight
    #       solr_parameters[:hl] = true
    #       solr_parameters.append_highlight_field field.field
    #     end

    #     next unless field.solr_params

    #     field.solr_params.each do |k, v|
    #       solr_parameters[:"f.#{field.field}.#{k}"] = v
    #     end
    #   end
    # end

    # ###
    # # copy paging params from BL app over to solr, changing
    # # app level per_page and page to Solr rows and start.
    # def add_paging_to_solr(solr_params)
    #   rows(solr_params[:rows] || 10) if rows.nil?

    #   solr_params[:rows] = rows

    #   solr_params[:start] = start if start.nonzero?
    # end

    # ###
    # # copy sorting params from BL app over to solr
    # def add_sorting_to_solr(solr_parameters)
    #   solr_parameters[:sort] = sort if sort.present?
    # end

    # # Remove the group parameter if we've faceted on the group field (e.g. for the full results for a group)
    # def add_group_config_to_solr solr_parameters
    #   solr_parameters[:group] = false if search_state.filter(grouped_key_for_results).any?
    # end

    # def add_facet_paging_to_solr(solr_params)
    #   return if facet.blank?

    #   facet_config = blacklight_config.facet_fields[facet]

    #   solr_params[:rows] = 0

    #   limit = if solr_params["facet.limit"]
    #             solr_params["facet.limit"].to_i
    #           else
    #             facet_config.fetch(:more_limit, blacklight_config.default_more_limit)
    #           end

    #   page = search_state.facet_page
    #   sort = search_state.facet_sort
    #   prefix = search_state.facet_prefix
    #   offset = (page - 1) * limit

    #   if facet_config.json
    #     add_solr_facet_json_params(solr_parameters, facet, facet_config, limit: limit + 1, offset: offset, sort: sort, prefix: prefix)
    #     return
    #   end

    #   # Now override with our specific things for fetching facet values
    #   facet_ex = facet_config.respond_to?(:ex) ? facet_config.ex : nil
    #   solr_params[:'facet.field'] = with_ex_local_param(facet_ex, facet_config.field)

    #   # Need to set as f.facet_field.facet.* to make sure we
    #   # override any field-specific default in the solr request handler.
    #   solr_params[:"f.#{facet_config.field}.facet.limit"] = limit + 1
    #   solr_params[:"f.#{facet_config.field}.facet.offset"] = offset
    #   solr_params[:"f.#{facet_config.field}.facet.sort"] = sort if sort
    #   solr_params[:"f.#{facet_config.field}.facet.prefix"] = prefix if prefix
    # end

    # def add_facet_suggestion_parameters(solr_params)
    #   return if facet.blank? || facet_suggestion_query.blank?

    #   solr_params[:'facet.contains'] = facet_suggestion_query[0..50]
    #   solr_params[:'facet.contains.ignoreCase'] = true
    # end

    # # Look up facet limit for given facet_field. Will look at config, and
    # # if config is 'true' will look up from Solr @response if available. If
    # # no limit is avaialble, returns nil. Used from #add_facetting_to_solr
    # # to supply f.fieldname.facet.limit values in solr request (no @response
    # # available), and used in display (with @response available) to create
    # # a facet paginator with the right limit.
    # def facet_limit_for(facet_field)
    #   facet = blacklight_config.facet_fields[facet_field]
    #   return if facet.blank?

    #   return unless facet.limit

    #   facet.limit == true ? blacklight_config.default_facet_limit : facet.limit
    # end

    # # Support facet paging and 'more'
    # # links, by sending a facet.limit one more than what we
    # # want to page at, according to configured facet limits.
    # def facet_limit_with_pagination(field_name)
    #   limit = facet_limit_for(field_name)

    #   return if limit.nil?

    #   if limit > 0
    #     limit + 1
    #   else
    #     limit
    #   end
    # end

    # ##
    # # A helper method used for generating solr LocalParams, put quotes
    # # around the term unless it's a bare-word. Escape internal quotes
    # # if needed.
    # def solr_param_quote(val, options = {})
    #   val = val.to_s
    #   options[:quote] ||= '"'
    #   unless val =~ /^[a-zA-Z0-9$_\-\^]+$/
    #     val = options[:quote] +
    #           # Yes, we need crazy escaping here, to deal with regexp esc too!
    #           val.gsub("'", "\\\\'").gsub('"', "\\\\\"") +
    #           options[:quote]
    #   end
    #   val
    # end

    private

    ##
    # Convert a facet/value pair into a solr fq parameter

    def facet_value_to_fq_string(facet_field, value, use_local_params: true)
      facet_config = blacklight_config.facet_fields[facet_field]

      index_field = facet_config.field if facet_config && !facet_config.query
      index_field ||= facet_field

      if facet_config && facet_config.query
        raise "facet value not found, {value}" unless facet_config.query[value]

        facet_config.query[value][:fq]
      elsif value.is_a?(Range)
        prefix = "{!#{local_params.join(' ')}}" unless local_params.empty?
        start = value.begin || '*'
        finish = value.end || '*'
        debugger

        "#{prefix}#{index_field}:[#{start} TO #{finish}]"
      elsif value == Blacklight::SearchState::FilterField::MISSING
        debugger

        "-#{index_field}:[* TO *]"
      else
        { 'term' => { index_field => convert_to_term_value(value) } }
      end
    end

    def facet_inclusive_value_to_fq_string(facet_field, values)
      return if values.blank?

      return facet_value_to_fq_string(facet_field, values.first) if values.length == 1

      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config && facet_config.tag

      solr_filters = values.each_with_object({}).with_index do |(v, h), index|
        h["f_inclusive.#{facet_field}.#{index}"] = facet_value_to_fq_string(facet_field, v, use_local_params: false)
      end

      filter_query = solr_filters.keys.map do |k|
        "{!query v=$#{k}}"
      end.join(' OR ')

      ["{!lucene#{" #{local_params.join(' ')}" unless local_params.empty?}}#{filter_query}", solr_filters]
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

    # ##
    # # The key to use to retrieve the grouped field to display
    # def grouped_key_for_results
    #   blacklight_config.view_config(action_name: :index).group
    # end

    # TODO: Identical to method in Solr search builder. Perhaps move to blacklight_config?
    def facet_fields_to_include_in_request
      blacklight_config.facet_fields.select do |_field_name, facet|
        facet.include_in_request || (facet.include_in_request.nil? && blacklight_config.add_facet_fields_to_solr_request)
      end
    end

    # def search_state
    #   return super if defined?(super)

    #   @search_state ||= Blacklight::SearchState.new(blacklight_params, blacklight_config)
    # end

    # def add_search_field_query_builder_params(solr_parameters)
    #   q, additional_parameters = search_field.query_builder.call(self, search_field, solr_parameters)

    #   solr_parameters.append_query q
    #   solr_parameters.merge!(additional_parameters) if additional_parameters
    # end

    # def add_search_field_with_local_parameters(solr_parameters)
    #   local_params = search_field.solr_local_parameters.map do |key, val|
    #     "#{key}=#{solr_param_quote(val, quote: "'")}"
    #   end.join(" ")
    #   solr_parameters.append_query "{!#{local_params}}#{search_state.query_param}"

    #   ##
    #   # Set Solr spellcheck.q to be original user-entered query, without
    #   # our local params, otherwise it'll try and spellcheck the local
    #   # params!
    #   solr_parameters["spellcheck.q"] ||= search_state.query_param
    # end
  end
end
