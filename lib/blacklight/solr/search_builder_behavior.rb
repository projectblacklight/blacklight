module Blacklight::Solr
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain = [
        :default_solr_parameters, :add_query_to_solr, :add_facet_fq_to_solr,
        :add_facetting_to_solr, :add_solr_fields_to_query, :add_paging_to_solr,
        :add_sorting_to_solr, :add_group_config_to_solr, :add_facet_paging_to_solr
      ]
    end

    ####
    # Start with general defaults from BL config. Need to use custom
    # merge to dup values, to avoid later mutating the original by mistake.
    def default_solr_parameters(solr_parameters)
      blacklight_config.default_solr_params.each do |key, value|
        solr_parameters[key] = if value.respond_to? :deep_dup
          value.deep_dup
        elsif value.respond_to? :dup and value.duplicable?
          value.dup
        else
          value
        end
      end
    end

    ##
    # Take the user-entered query, and put it in the solr params,
    # including config's "search field" params for current search field.
    # also include setting spellcheck.q.
    def add_query_to_solr(solr_parameters)
      ###
      # Merge in search field configured values, if present, over-writing general
      # defaults
      ###
      # legacy behavior of user param :qt is passed through, but over-ridden
      # by actual search field config if present. We might want to remove
      # this legacy behavior at some point. It does not seem to be currently
      # rspec'd.
      solr_parameters[:qt] = blacklight_params[:qt] if blacklight_params[:qt]

      if search_field
        solr_parameters[:qt] = search_field.qt
        solr_parameters.merge!( search_field.solr_parameters) if search_field.solr_parameters
      end

      ##
      # Create Solr 'q' including the user-entered q, prefixed by any
      # solr LocalParams in config, using solr LocalParams syntax.
      # http://wiki.apache.org/solr/LocalParams
      ##
      if (search_field && hash = search_field.solr_local_parameters)
        local_params = hash.collect do |key, val|
          key.to_s + "=" + solr_param_quote(val, :quote => "'")
        end.join(" ")
        solr_parameters[:q] = "{!#{local_params}}#{blacklight_params[:q]}"

        ##
        # Set Solr spellcheck.q to be original user-entered query, without
        # our local params, otherwise it'll try and spellcheck the local
        # params!
        solr_parameters["spellcheck.q"] ||= blacklight_params[:q]
      elsif blacklight_params[:q].is_a? Hash
        q = blacklight_params[:q]
        solr_parameters[:q] = if q.values.any?(&:blank?)
          # if any field parameters are empty, exclude _all_ results
          "{!lucene}NOT *:*"
        else
          "{!lucene}" + q.map do |field, values|
            "#{field}:(#{ Array(values).map { |x| solr_param_quote(x) }.join(" OR ")})"
          end.join(" AND ")
        end

        solr_parameters[:spellcheck] = 'false'
      elsif blacklight_params[:q]
        solr_parameters[:q] = blacklight_params[:q]
      end
    end

    ##
    # Add any existing facet limits, stored in app-level HTTP query
    # as :f, to solr as appropriate :fq query.
    def add_facet_fq_to_solr(solr_parameters)

      # convert a String value into an Array
      if solr_parameters[:fq].is_a? String
        solr_parameters[:fq] = [solr_parameters[:fq]]
      end

      # :fq, map from :f.
      if ( blacklight_params[:f])
        f_request_params = blacklight_params[:f]

        f_request_params.each_pair do |facet_field, value_list|
          Array(value_list).each do |value|
            next if value.blank? # skip empty strings
            solr_parameters.append_filter_query facet_value_to_fq_string(facet_field, value)
          end
        end
      end
    end

    ##
    # Add appropriate Solr facetting directives in, including
    # taking account of our facet paging/'more'.  This is not
    # about solr 'fq', this is about solr facet.* params.
    def add_facetting_to_solr(solr_parameters)
      # While not used by BL core behavior, legacy behavior seemed to be
      # to accept incoming params as "facet.field" or "facets", and add them
      # on to any existing facet.field sent to Solr. Legacy behavior seemed
      # to be accepting these incoming params as arrays (in Rails URL with []
      # on end), or single values. At least one of these is used by
      # Stanford for "faux hieararchial facets".
      if blacklight_params.has_key?("facet.field") || blacklight_params.has_key?("facets")
        solr_parameters[:"facet.field"].concat( [blacklight_params["facet.field"], blacklight_params["facets"]].flatten.compact ).uniq!
      end

      facet_fields_to_include_in_request.each do |field_name, facet|
        solr_parameters[:facet] ||= true

        case
          when facet.pivot
            solr_parameters.append_facet_pivot with_ex_local_param(facet.ex, facet.pivot.join(","))
          when facet.query
            solr_parameters.append_facet_query facet.query.map { |k, x| with_ex_local_param(facet.ex, x[:fq]) }
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

        # Support facet paging and 'more'
        # links, by sending a facet.limit one more than what we
        # want to page at, according to configured facet limits.
        solr_parameters[:"f.#{facet.field}.facet.limit"] = (facet_limit_for(field_name) + 1) if facet_limit_for(field_name)
      end
    end

    def add_solr_fields_to_query solr_parameters
      blacklight_config.show_fields.select(&method(:should_add_field_to_request?)).each do |field_name, field|
        if field.solr_params
          field.solr_params.each do |k, v|
            solr_parameters[:"f.#{field.field}.#{k}"] = v
          end
        end
      end

      blacklight_config.index_fields.select(&method(:should_add_field_to_request?)).each do |field_name, field|
        if field.highlight
          solr_parameters[:hl] = true
          solr_parameters.append_highlight_field field.field
        end

        if field.solr_params
          field.solr_params.each do |k, v|
            solr_parameters[:"f.#{field.field}.#{k}"] = v
          end
        end
      end
    end

    ###
    # copy paging params from BL app over to solr, changing
    # app level per_page and page to Solr rows and start.
    def add_paging_to_solr(solr_params)
      rows(solr_params[:rows] || 10) if rows.nil?

      solr_params[:rows] = rows

      if start != 0
        solr_params[:start] = start
      end
    end

    ###
    # copy sorting params from BL app over to solr
    def add_sorting_to_solr(solr_parameters)
      solr_parameters[:sort] = sort unless sort.blank?
    end

    # Remove the group parameter if we've faceted on the group field (e.g. for the full results for a group)
    def add_group_config_to_solr solr_parameters
      if blacklight_params[:f] and blacklight_params[:f][grouped_key_for_results]
        solr_parameters[:group] = false
      end
    end

    def add_facet_paging_to_solr(solr_params)
      return unless facet.present?

      facet_config = blacklight_config.facet_fields[facet]

      # Now override with our specific things for fetching facet values
      solr_params[:"facet.field"] = with_ex_local_param((facet_config.ex if facet_config.respond_to?(:ex)), facet)

      limit = if scope.respond_to?(:facet_list_limit)
          scope.facet_list_limit.to_s.to_i
        elsif solr_params["facet.limit"]
          solr_params["facet.limit"].to_i
        else
          20
        end

      # Need to set as f.facet_field.facet.* to make sure we
      # override any field-specific default in the solr request handler.
      solr_params[:"f.#{facet}.facet.limit"]  = limit + 1
      solr_params[:"f.#{facet}.facet.offset"] = ( blacklight_params.fetch(blacklight_config.facet_paginator_class.request_keys[:page] , 1).to_i - 1 ) * ( limit )
      solr_params[:"f.#{facet}.facet.sort"] = blacklight_params[  blacklight_config.facet_paginator_class.request_keys[:sort] ] if  blacklight_params[  blacklight_config.facet_paginator_class.request_keys[:sort] ]
      solr_params[:rows] = 0
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

    ##
    # A helper method used for generating solr LocalParams, put quotes
    # around the term unless it's a bare-word. Escape internal quotes
    # if needed.
    def solr_param_quote(val, options = {})
      options[:quote] ||= '"'
      unless val =~ /^[a-zA-Z0-9$_\-\^]+$/
        val = options[:quote] +
          # Yes, we need crazy escaping here, to deal with regexp esc too!
          val.gsub("'", "\\\\\'").gsub('"', "\\\\\"") +
          options[:quote]
      end
      return val
    end

    private

    ##
    # Convert a facet/value pair into a solr fq parameter
    def facet_value_to_fq_string(facet_field, value)
      facet_config = blacklight_config.facet_fields[facet_field]

      solr_field = facet_config.field if facet_config and not facet_config.query
      solr_field ||= facet_field

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag

      prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?

      case
        when (facet_config and facet_config.query)
          facet_config.query[value][:fq]
        when (facet_config and facet_config.date)
          # in solr 3.2+, this could be replaced by a !term query
          "#{prefix}#{solr_field}:#{RSolr.solr_escape(value)}"
        when (value.is_a?(DateTime) or value.is_a?(Time))
          "#{prefix}#{solr_field}:#{RSolr.solr_escape(value.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))}"
        when value.is_a?(Date)
          # rubocop:disable Rails/Date
          "#{prefix}#{solr_field}:#{RSolr.solr_escape(value.to_time(:local).strftime("%Y-%m-%dT%H:%M:%SZ"))}"
          # rubocop:enable Rails/Date
        when (value.is_a?(TrueClass) or value.is_a?(FalseClass) or value == 'true' or value == 'false'),
             (value.is_a?(Integer) or (value.to_i.to_s == value if value.respond_to? :to_i)),
             (value.is_a?(Float) or (value.to_f.to_s == value if value.respond_to? :to_f))
          "#{prefix}#{solr_field}:#{RSolr.solr_escape(value.to_s)}"
        when value.is_a?(Range)
          "#{prefix}#{solr_field}:[#{value.first} TO #{value.last}]"
        else
          "{!raw f=#{solr_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
      end
    end

    ##
    # The key to use to retrieve the grouped field to display
    def grouped_key_for_results
      blacklight_config.index.group
    end

    def facet_fields_to_include_in_request
      blacklight_config.facet_fields.select do |field_name,facet|
        facet.include_in_request || (facet.include_in_request.nil? && blacklight_config.add_facet_fields_to_solr_request)
      end
    end
  end
end
