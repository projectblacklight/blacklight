# frozen_string_literal: true

module Blacklight::Solr
  # This depends on being imported into a class that extends AbstractSearchBuilder
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain = [
        :default_solr_parameters,
        :add_search_field_default_parameters,
        :add_query_to_solr,
        :add_facet_fq_to_solr,
        :add_facetting_to_solr,
        :add_solr_fields_to_query,
        :add_paging_to_solr,
        :add_sorting_to_solr,
        :add_group_config_to_solr,
        :add_adv_search_clauses,
        :add_facets_for_advanced_search_form,
        :add_facet_paging_to_solr,
        :add_facet_suggestion_parameters,
        :add_additional_filters
      ]
    end

    def limit_to_specific_records(solr_parameters, document_ids)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += ["{!terms f=id}#{document_ids.join(',')}"]
    end

    ##
    # Pagination parameters for selecting the previous and next documents
    # out of a result set.
    def previous_and_next_document_params(index, window = 1)
      solr_params = blacklight_config.document_pagination_params.dup

      if solr_params.empty?
        solr_params[:fl] = blacklight_config.document_model.unique_key
      end

      if index > 0
        solr_params[:start] = index - window # get one before
        solr_params[:rows] = (2 * window) + 1 # and one after
      else
        solr_params[:start] = 0 # there is no previous doc
        solr_params[:rows] = 2 * window # but there should be one after
      end

      solr_params[:facet] = false
      solr_params
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
      return unless search_state.query_param

      bool_query = search_field.clause_params.transform_values { |v| v.merge(query: search_state.query_param) }
      solr_parameters["spellcheck.q"] ||= search_state.query_param

      solr_parameters.append_boolean_query(:must, bool_query)
    end

    # Transform "clause" parameters into the Solr JSON Query DSL
    def add_adv_search_clauses(solr_parameters)
      return if search_state.clause_params.blank?

      # We need to specify lucene as the top-level defType when using JSON Query DSL in Solr versions
      # between 7.2.0 & 9.4.0. After 9.4.0 this is no longer necessary, but also not harmful to include.
      solr_parameters[:defType] = 'lucene'

      # Disable spellcheck, which doesn't work when using JSON Query DSL
      solr_parameters[:spellcheck] = 'false'

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

    # Merge the advanced search form parameters into the solr parameters
    # @param [Hash] solr_parameters the current solr parameters
    # @return [Hash] the solr parameters with the additional advanced search form parameters
    def add_facets_for_advanced_search_form(solr_parameters)
      return unless search_state.controller&.action_name == 'advanced_search' &&
                    blacklight_config.advanced_search[:form_solr_parameters]

      solr_parameters.merge!(blacklight_config.advanced_search[:form_solr_parameters])
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
        filter_query_builder_class_or_proc = filter.config.filter_query_builder || DefaultFilterQueryBuilder
        if filter_query_builder_class_or_proc.is_a?(Class)
          filter_query_builder = filter_query_builder_class_or_proc.new(blacklight_config: blacklight_config)
          filter_query, subqueries = filter_query_builder.call(filter, solr_parameters)
        else
          # TODO: Maybe deprecate proc?
          filter_query, subqueries = filter_query_builder_class_or_proc.call(self, filter, solr_parameters)
        end

        Array(filter_query).each do |fq|
          solr_parameters.append_filter_query(fq)
        end
        solr_parameters.merge!(subqueries) if subqueries
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

      solr_parameters[:json][:facet][field_name] = field_config.compact_blank
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

        facet.solr_params&.each do |k, v|
          solr_parameters[:"f.#{facet.field}.#{k}"] = v
        end

        limit = facet_limit_with_pagination(field_name)
        solr_parameters[:"f.#{facet.field}.facet.limit"] = limit if limit
      end
    end

    def add_solr_fields_to_query solr_parameters
      blacklight_config.show_fields.select(&method(:should_add_field_to_request?)).each_value do |field|
        field.solr_params&.each do |k, v|
          solr_parameters[:"f.#{field.field}.#{k}"] = v
        end
      end

      blacklight_config.index_fields.select(&method(:should_add_field_to_request?)).each_value do |field|
        if field.highlight
          solr_parameters[:hl] = true
          solr_parameters.append_highlight_field field.field
        end

        field.solr_params&.each do |k, v|
          solr_parameters[:"f.#{field.field}.#{k}"] = v
        end
      end
    end

    ###
    # copy paging params from BL app over to solr, changing
    # app level per_page and page to Solr rows and start.
    def add_paging_to_solr(solr_params)
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

    def add_facet_suggestion_parameters(solr_params)
      return if facet.blank? || facet_suggestion_query.blank?

      solr_params[:'facet.contains'] = facet_suggestion_query[0..50]
      solr_params[:'facet.contains.ignoreCase'] = true
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
    # no limit is available, returns nil. Used from #add_facetting_to_solr
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
              val.gsub("'", "\\\\'").gsub('"', "\\\\\"") +
              options[:quote]
      end
      val
    end

    private

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

    def request
      Blacklight::Solr::Request.new
    end
  end
end
