# frozen_string_literal: true

module Blacklight::Solr
  module FacetSearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      include Blacklight::Solr::SearchBuilderBehavior
      # Override the default processor chain to include facet-related processors (and exclude paging, sorting, and grouping)
      self.default_processor_chain += [
        :add_facet_paging_to_solr,
        :add_facet_suggestion_parameters
      ]
      self.default_processor_chain -= [
        :add_paging_to_solr,
        :add_sorting_to_solr,
        :add_group_config_to_solr
      ]
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
  end
end
