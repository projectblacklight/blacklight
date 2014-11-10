module Blacklight
  ##
  # This module contains methods that are specified by SolrHelper.solr_search_params_logic
  # They transform user parameters into parameters that are sent as a request to Solr when
  # RequestBuilders#solr_search_params is called.
  #
  module RequestBuilders
    extend ActiveSupport::Concern

    included do
      # We want to install a class-level place to keep
      # solr_search_params_logic method names. Compare to before_filter,
      # similar design. Since we're a module, we have to add it in here.
      # There are too many different semantic choices in ruby 'class variables',
      # we choose this one for now, supplied by Rails.
      class_attribute :solr_search_params_logic

      # Set defaults. Each symbol identifies a _method_ that must be in
      # this class, taking two parameters (solr_parameters, user_parameters)
      # Can be changed in local apps or by plugins, eg:
      # CatalogController.include ModuleDefiningNewMethod
      # CatalogController.solr_search_params_logic += [:new_method]
      # CatalogController.solr_search_params_logic.delete(:we_dont_want)
      self.solr_search_params_logic = [:default_solr_parameters , :add_query_to_solr, :add_facet_fq_to_solr, :add_facetting_to_solr, :add_solr_fields_to_query, :add_paging_to_solr, :add_sorting_to_solr, :add_group_config_to_solr ]
    end

    # @returns a params hash for searching solr.
    # The CatalogController #index action uses this.
    # Solr parameters can come from a number of places. From lowest
    # precedence to highest:
    #  1. General defaults in blacklight config (are trumped by)
    #  2. defaults for the particular search field identified by  params[:search_field] (are trumped by)
    #  3. certain parameters directly on input HTTP query params
    #     * not just any parameter is grabbed willy nilly, only certain ones are allowed by HTTP input)
    #     * for legacy reasons, qt in http query does not over-ride qt in search field definition default.
    #  4.  extra parameters passed in as argument.
    #
    # spellcheck.q will be supplied with the [:q] value unless specifically
    # specified otherwise.
    #
    # Incoming parameter :f is mapped to :fq solr parameter.
    def solr_search_params(user_params = params || {})
      Blacklight::Solr::Request.new.tap do |solr_parameters|
        solr_search_params_logic.each do |method_name|
          send(method_name, solr_parameters, user_params)
        end
      end
    end

    ####
    # Start with general defaults from BL config. Need to use custom
    # merge to dup values, to avoid later mutating the original by mistake.
    def default_solr_parameters(solr_parameters, user_params)
      blacklight_config.default_solr_params.each do |key, value|
        solr_parameters[key] = value.dup rescue value
      end
    end

    ##
    # Take the user-entered query, and put it in the solr params,
    # including config's "search field" params for current search field.
    # also include setting spellcheck.q.
    def add_query_to_solr(solr_parameters, user_parameters)
      ###
      # Merge in search field configured values, if present, over-writing general
      # defaults
      ###
      # legacy behavior of user param :qt is passed through, but over-ridden
      # by actual search field config if present. We might want to remove
      # this legacy behavior at some point. It does not seem to be currently
      # rspec'd.
      solr_parameters[:qt] = user_parameters[:qt] if user_parameters[:qt]

      search_field_def = search_field_def_for_key(user_parameters[:search_field])
      if (search_field_def)
        solr_parameters[:qt] = search_field_def.qt
        solr_parameters.merge!( search_field_def.solr_parameters) if search_field_def.solr_parameters
      end

      ##
      # Create Solr 'q' including the user-entered q, prefixed by any
      # solr LocalParams in config, using solr LocalParams syntax.
      # http://wiki.apache.org/solr/LocalParams
      ##
      if (search_field_def && hash = search_field_def.solr_local_parameters)
        local_params = hash.collect do |key, val|
          key.to_s + "=" + solr_param_quote(val, :quote => "'")
        end.join(" ")
        solr_parameters[:q] = "{!#{local_params}}#{user_parameters[:q]}"
      else
        solr_parameters[:q] = user_parameters[:q] if user_parameters[:q]
      end


      ##
      # Set Solr spellcheck.q to be original user-entered query, without
      # our local params, otherwise it'll try and spellcheck the local
      # params! Unless spellcheck.q has already been set by someone,
      # respect that.
      #
      # TODO: Change calling code to expect this as a symbol instead of
      # a string, for consistency? :'spellcheck.q' is a symbol. Right now
      # rspec tests for a string, and can't tell if other code may
      # insist on a string.
      solr_parameters["spellcheck.q"] = user_parameters[:q] unless solr_parameters["spellcheck.q"]
    end

    ##
    # Add any existing facet limits, stored in app-level HTTP query
    # as :f, to solr as appropriate :fq query.
    def add_facet_fq_to_solr(solr_parameters, user_params)

      # convert a String value into an Array
      if solr_parameters[:fq].is_a? String
        solr_parameters[:fq] = [solr_parameters[:fq]]
      end

      # :fq, map from :f.
      if ( user_params[:f])
        f_request_params = user_params[:f]

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
    def add_facetting_to_solr(solr_parameters, user_params)
      # While not used by BL core behavior, legacy behavior seemed to be
      # to accept incoming params as "facet.field" or "facets", and add them
      # on to any existing facet.field sent to Solr. Legacy behavior seemed
      # to be accepting these incoming params as arrays (in Rails URL with []
      # on end), or single values. At least one of these is used by
      # Stanford for "faux hieararchial facets".
      if user_params.has_key?("facet.field") || user_params.has_key?("facets")
        solr_parameters[:"facet.field"].concat( [user_params["facet.field"], user_params["facets"]].flatten.compact ).uniq!
      end

      blacklight_config.facet_fields.select { |field_name,facet|
        facet.include_in_request || (facet.include_in_request.nil? && blacklight_config.add_facet_fields_to_solr_request)
      }.each do |field_name, facet|
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

    def add_solr_fields_to_query solr_parameters, user_parameters
      blacklight_config.show_fields.select(&method(:should_add_to_solr)).each do |field_name, field|
        if field.solr_params
          field.solr_params.each do |k, v|
            solr_parameters[:"f.#{field.field}.#{k}"] = v
          end
        end
      end

      blacklight_config.index_fields.select(&method(:should_add_to_solr)).each do |field_name, field|
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
    def add_paging_to_solr(solr_params, user_params)

      # user-provided parameters should override any default row
      solr_params[:rows] = user_params[:rows].to_i unless user_params[:rows].blank?
      solr_params[:rows] = user_params[:per_page].to_i unless user_params[:per_page].blank?

      # configuration defaults should only set a default value, not override a value set elsewhere (e.g. search field parameters)
      solr_params[:rows] ||= blacklight_config.default_per_page unless blacklight_config.default_per_page.blank?
      solr_params[:rows] ||= blacklight_config.per_page.first unless blacklight_config.per_page.blank?

      # set a reasonable default
      Rails.logger.info "Solr :rows parameter not set (by the user, configuration, or default solr parameters); using 10 rows by default"
      solr_params[:rows] ||= 10

      # ensure we don't excede the max page size
      solr_params[:rows] = blacklight_config.max_per_page if solr_params[:rows].to_i > blacklight_config.max_per_page
      unless user_params[:page].blank?
        solr_params[:start] = solr_params[:rows].to_i * (user_params[:page].to_i - 1)
        solr_params[:start] = 0 if solr_params[:start].to_i < 0
      end

    end

    ###
    # copy sorting params from BL app over to solr
    def add_sorting_to_solr(solr_parameters, user_params)
      if user_params[:sort].blank? and sort_field = blacklight_config.default_sort_field
        # no sort param provided, use default
        solr_parameters[:sort] = sort_field.sort unless sort_field.sort.blank?
      elsif sort_field = blacklight_config.sort_fields[user_params[:sort]]
        # check for sort field key
        solr_parameters[:sort] = sort_field.sort unless sort_field.sort.blank?
      else
        # just pass the key through
        solr_parameters[:sort] = user_params[:sort]
      end
    end

    # Remove the group parameter if we've faceted on the group field (e.g. for the full results for a group)
    def add_group_config_to_solr solr_parameters, user_parameters
      if user_parameters[:f] and user_parameters[:f][grouped_key_for_results]
        solr_parameters[:group] = false
      end
    end

    def with_ex_local_param(ex, value)
      if ex
        "{!ex=#{ex}}#{value}"
      else
        value
      end
    end

    private

    ##
    # Convert a facet/value pair into a solr fq parameter
    def facet_value_to_fq_string(facet_field, value)
      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag

      prefix = ""
      prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?

      fq = case
        when (facet_config and facet_config.query)
          facet_config.query[value][:fq]
        when (facet_config and facet_config.date)
          # in solr 3.2+, this could be replaced by a !term query
          "#{prefix}#{facet_field}:#{RSolr.escape(value)}"
        when (value.is_a?(DateTime) or value.is_a?(Date) or value.is_a?(Time))
          "#{prefix}#{facet_field}:#{RSolr.escape(value.to_time.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))}"
        when (value.is_a?(TrueClass) or value.is_a?(FalseClass) or value == 'true' or value == 'false'),
             (value.is_a?(Integer) or (value.to_i.to_s == value if value.respond_to? :to_i)),
             (value.is_a?(Float) or (value.to_f.to_s == value if value.respond_to? :to_f))
          then
            if value[0] != '-'
              "#{prefix}#{facet_field}:#{value}"
            else
              "#{prefix}#{facet_field}:\\#{value}"
            end

        when value.is_a?(Range)
          "#{prefix}#{facet_field}:[#{value.first} TO #{value.last}]"
        else
          "{!raw f=#{facet_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
      end


    end
  end
end
