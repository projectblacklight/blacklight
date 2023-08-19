# frozen_string_literal: true

module Blacklight::Solr
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain = [
        :default_solr_parameters, :add_search_field_default_parameters,
        :add_query_to_solr, :add_facet_fq_to_solr,
        :add_facetting_to_solr, :add_solr_fields_to_query, :add_paging_to_solr,
        :add_sorting_to_solr, :add_group_config_to_solr,
        :add_facet_paging_to_solr, :add_adv_search_clauses,
        :add_additional_filters
      ]
    end

    ####
    # Start with general defaults from BL config. Need to use custom
    # merge to dup values, to avoid later mutating the original by mistake.
    def default_solr_parameters(solr_parameters)
      blacklight_config.default_solr_params.each do |key, value|
        solr_parameters[key] ||= if value.respond_to? :deep_dup
                                   value.deep_dup
                                 elsif value.respond_to?(:dup) && value.duplicable?
                                   value.dup
                                 else
                                   value
                                 end
      end
    end

    def add_search_field_default_parameters(solr_parameters)
      ###
      # Merge in search field configured values, if present, over-writing general
      # defaults
      if search_field
        solr_parameters[:qt] = search_field.qt if search_field.qt

        solr_parameters.deep_merge!(search_field.solr_parameters) if search_field.solr_parameters
      end
    end

    ##
    # Take the user-entered query, and put it in the solr params,
    # including config's "search field" params for current search field.
    # also include setting spellcheck.q.
    def add_query_to_solr(solr_parameters)
      ##
      # Create Solr 'q' including the user-entered q, prefixed by any
      # solr LocalParams in config, using solr LocalParams syntax.
      # http://wiki.apache.org/solr/LocalParams
      ##
      if search_field&.query_builder.present?
        add_search_field_query_builder_params(solr_parameters)
      elsif search_field&.clause_params.present?
        add_search_field_with_json_query_parameters(solr_parameters)
      elsif search_field&.solr_local_parameters.present?
        add_search_field_with_local_parameters(solr_parameters)
      elsif !search_state&.query_param.is_a?(Hash)
        solr_parameters.append_query search_state.query_param
      end
    end

    def add_additional_filters(solr_parameters, additional_filters = nil)
      q = additional_filters || @additional_filters

      return if q.blank?

      if q.values.any?(&:blank?)
        # if any field parameters are empty, exclude _all_ results
        solr_parameters.append_query "{!lucene}NOT *:*"
      else
        composed_query = q.map do |field, values|
          "#{field}:(#{Array(values).map { |x| solr_param_quote(x) }.join(' OR ')})"
        end.join(" AND ")

        solr_parameters.append_query "{!lucene}#{composed_query}"
      end

      solr_parameters[:defType] = 'lucene'
      solr_parameters[:spellcheck] = 'false'
    end

    def add_search_field_with_json_query_parameters(solr_parameters)
      bool_query = search_field.clause_params.transform_values { |v| v.merge(query: search_state.query_param) }
      solr_parameters["spellcheck.q"] ||= search_state.query_param

      solr_parameters.append_boolean_query(:must, bool_query)
    end

    # Transform "clause" parameters into the Solr JSON Query DSL
    def add_adv_search_clauses(solr_parameters)
      return if search_state.clause_params.blank?

      defaults = { must: [], must_not: [], should: [] }
      default_op = blacklight_params[:op]&.to_sym || :must
      solr_parameters[:mm] = 1 if default_op == :should && search_state.clause_params.values.any? { |clause| }

      search_state.clause_params.each_value do |clause|
        op, query = adv_search_clause(clause, default_op)
        next unless defaults.key?(op)

        solr_parameters.append_boolean_query(op, query)
      end
    end

    # @return [Array] the first element is the query operator and the second is the value to add
    def adv_search_clause(clause, default_op)
      op = clause[:op]&.to_sym || default_op
      field = (blacklight_config.search_fields || {})[clause[:field]] if clause[:field]

      return unless field&.clause_params && clause[:query].present?

      [op, field.clause_params.transform_values { |v| v.merge(query: clause[:query]) }]
    end

    ##
    # Add any existing facet limits, stored in app-level HTTP query
    # as :f, to solr as appropriate :fq query.
    def add_facet_fq_to_solr(solr_parameters)
      # convert a String value into an Array
      if solr_parameters[:fq].is_a? String
        solr_parameters[:fq] = [solr_parameters[:fq]]
      end

      search_state.filters.each do |filter|
        if filter.config.filter_query_builder
          filter_query, subqueries = filter.config.filter_query_builder.call(self, filter, solr_parameters)

          Array(filter_query).each do |fq|
            solr_parameters.append_filter_query(fq)
          end
          solr_parameters.merge!(subqueries) if subqueries
        else
          filter.values.compact_blank.each do |value|
            filter_query, subqueries = if value.is_a?(Array)
                                         facet_inclusive_value_to_fq_string(filter.key, value.compact_blank)
                                       else
                                         facet_value_to_fq_string(filter.config.key, value)
                                       end

            solr_parameters.append_filter_query filter_query
            solr_parameters.merge!(subqueries) if subqueries
          end
        end
      end
    end

    def add_solr_facet_json_params(solr_parameters, field_name, facet, **additional_parameters)
      solr_parameters[:json] ||= { facet: {} }
      solr_parameters[:json][:facet] ||= {}

      field_config = facet.json.respond_to?(:reverse_merge) ? facet.json : {}

      field_config = field_config.reverse_merge(
        type: 'terms',
        field: facet.field,
        limit: facet_limit_with_pagination(field_name)
      ).merge(additional_parameters)

      solr_parameters[:json][:facet][field_name] = field_config.select { |_k, v| v.present? }
    end

    ##
    # Add appropriate Solr facetting directives in, including
    # taking account of our facet paging/'more'.  This is not
    # about solr 'fq', this is about solr facet.* params.
    def add_facetting_to_solr(solr_parameters)
      facet_fields_to_include_in_request.each do |field_name, facet|
        solr_parameters[:facet] ||= true

        if facet.json
          add_solr_facet_json_params(solr_parameters, field_name, facet)
          next
        end

        if facet.pivot
          solr_parameters.append_facet_pivot with_ex_local_param(facet.ex, facet.pivot.join(","))
        elsif facet.query
          solr_parameters.append_facet_query facet.query.values.map { |x| with_ex_local_param(facet.ex, x[:fq]) }
        else
          solr_parameters.append_facet_fields with_ex_local_param(facet.ex, facet.field)
        end

        if facet.sort
          solr_parameters[:"f.#{facet.field}.facet.sort"] = facet.sort
        end

        if facet.solr_params
          facet.solr_params.each do |k, v|
            solr_parameters[:"f.#{facet.field}.#{k}"] = v
          end
        end

        limit = facet_limit_with_pagination(field_name)
        solr_parameters[:"f.#{facet.field}.facet.limit"] = limit if limit
      end
    end

    def add_solr_fields_to_query solr_parameters
      blacklight_config.show_fields.select(&method(:should_add_field_to_request?)).each_value do |field|
        field.solr_params.each do |k, v|
          solr_parameters[:"f.#{field.field}.#{k}"] = v
        end if field.solr_params
      end

      blacklight_config.index_fields.select(&method(:should_add_field_to_request?)).each_value do |field|
        if field.highlight
          solr_parameters[:hl] = true
          solr_parameters.append_highlight_field field.field
        end

        field.solr_params.each do |k, v|
          solr_parameters[:"f.#{field.field}.#{k}"] = v
        end if field.solr_params
      end
    end

    ###
    # copy paging params from BL app over to solr, changing
    # app level per_page and page to Solr rows and start.
    def add_paging_to_solr(solr_params)
      rows(solr_params[:rows] || 10) if rows.nil?

      solr_params[:rows] = rows

      solr_params[:start] = start if start.nonzero?
    end

    ###
    # copy sorting params from BL app over to solr
    def add_sorting_to_solr(solr_parameters)
      solr_parameters[:sort] = sort if sort.present?
    end

    # Remove the group parameter if we've faceted on the group field (e.g. for the full results for a group)
    def add_group_config_to_solr solr_parameters
      solr_parameters[:group] = false if search_state.filter(grouped_key_for_results).any?
    end

    def add_facet_paging_to_solr(solr_params)
      return if facet.blank?

      facet_config = blacklight_config.facet_fields[facet]

      solr_params[:rows] = 0

      limit = if solr_params["facet.limit"]
                solr_params["facet.limit"].to_i
              else
                facet_config.fetch(:more_limit, blacklight_config.default_more_limit)
              end

      page = search_state.facet_page
      sort = search_state.facet_sort
      prefix = search_state.facet_prefix
      offset = (page - 1) * limit

      if facet_config.json
        add_solr_facet_json_params(solr_parameters, facet, facet_config, limit: limit + 1, offset: offset, sort: sort, prefix: prefix)
        return
      end

      # Now override with our specific things for fetching facet values
      facet_ex = facet_config.respond_to?(:ex) ? facet_config.ex : nil
      solr_params[:'facet.field'] = with_ex_local_param(facet_ex, facet_config.field)

      # Need to set as f.facet_field.facet.* to make sure we
      # override any field-specific default in the solr request handler.
      solr_params[:"f.#{facet_config.field}.facet.limit"] = limit + 1
      solr_params[:"f.#{facet_config.field}.facet.offset"] = offset
      solr_params[:"f.#{facet_config.field}.facet.sort"] = sort if sort
      solr_params[:"f.#{facet_config.field}.facet.prefix"] = prefix if prefix
    end

    def with_ex_local_param(ex, value)
      if ex
        "{!ex=#{ex}}#{value}"
      else
        value
      end
    end

    # Look up facet limit for given facet_field. Will look at config, and
    # if config is 'true' will look up from Solr @response if available. If
    # no limit is avaialble, returns nil. Used from #add_facetting_to_solr
    # to supply f.fieldname.facet.limit values in solr request (no @response
    # available), and used in display (with @response available) to create
    # a facet paginator with the right limit.
    def facet_limit_for(facet_field)
      facet = blacklight_config.facet_fields[facet_field]
      return if facet.blank?

      if facet.limit
        facet.limit == true ? blacklight_config.default_facet_limit : facet.limit
      end
    end

    # Support facet paging and 'more'
    # links, by sending a facet.limit one more than what we
    # want to page at, according to configured facet limits.
    def facet_limit_with_pagination(field_name)
      limit = facet_limit_for(field_name)

      return if limit.nil?

      if limit > 0
        limit + 1
      else
        limit
      end
    end

    ##
    # A helper method used for generating solr LocalParams, put quotes
    # around the term unless it's a bare-word. Escape internal quotes
    # if needed.
    def solr_param_quote(val, options = {})
      val = val.to_s
      options[:quote] ||= '"'
      unless val =~ /^[a-zA-Z0-9$_\-\^]+$/
        val = options[:quote] +
              # Yes, we need crazy escaping here, to deal with regexp esc too!
              val.gsub("'", "\\\\\'").gsub('"', "\\\\\"") +
              options[:quote]
      end
      val
    end

    private

    ##
    # Convert a facet/value pair into a solr fq parameter
    # rubocop:disable Metrics/PerceivedComplexity
    def facet_value_to_fq_string(facet_field, value, use_local_params: true)
      facet_config = blacklight_config.facet_fields[facet_field]

      solr_field = facet_config.field if facet_config && !facet_config.query
      solr_field ||= facet_field

      local_params = []
      local_params << "tag=#{facet_config.tag}" if use_local_params && facet_config && facet_config.tag

      if facet_config && facet_config.query
        if facet_config.query[value]
          facet_config.query[value][:fq]
        else
          # exclude all documents if the custom facet key specified was not found
          '-*:*'
        end
      elsif value.is_a?(Range)
        prefix = "{!#{local_params.join(' ')}}" unless local_params.empty?
        "#{prefix}#{solr_field}:[#{value.first} TO #{value.last}]"
      elsif value == Blacklight::SearchState::FilterField::MISSING
        "-#{solr_field}:[* TO *]"
      else
        "{!term f=#{solr_field}#{" #{local_params.join(' ')}" unless local_params.empty?}}#{convert_to_term_value(value)}"
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

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

    ##
    # The key to use to retrieve the grouped field to display
    def grouped_key_for_results
      blacklight_config.view_config(action_name: :index).group
    end

    def facet_fields_to_include_in_request
      blacklight_config.facet_fields.select do |_field_name, facet|
        facet.include_in_request || (facet.include_in_request.nil? && blacklight_config.add_facet_fields_to_solr_request)
      end
    end

    def search_state
      return super if defined?(super)

      @search_state ||= Blacklight::SearchState.new(blacklight_params, blacklight_config)
    end

    def add_search_field_query_builder_params(solr_parameters)
      q, additional_parameters = search_field.query_builder.call(self, search_field, solr_parameters)

      solr_parameters.append_query q
      solr_parameters.merge!(additional_parameters) if additional_parameters
    end

    def add_search_field_with_local_parameters(solr_parameters)
      local_params = search_field.solr_local_parameters.map do |key, val|
        "#{key}=#{solr_param_quote(val, quote: "'")}"
      end.join(" ")
      solr_parameters.append_query "{!#{local_params}}#{search_state.query_param}"

      ##
      # Set Solr spellcheck.q to be original user-entered query, without
      # our local params, otherwise it'll try and spellcheck the local
      # params!
      solr_parameters["spellcheck.q"] ||= search_state.query_param
    end
  end
end
