# frozen_string_literal: true
module Blacklight
  # These are methods that are used at both the view helper and controller layers
  # They are only dependent on `blacklight_config` and `@response`
  #
  module Facet
    delegate :facet_configuration_for_field, to: :blacklight_config

    def facet_paginator(field_config, response_data)
      blacklight_config.facet_paginator_class.new(
        response_data.items,
        sort: response_data.sort,
        offset: response_data.offset,
        prefix: response_data.prefix,
        limit: facet_limit_for(field_config.key)
      )
    end

    # @param fields [Array<String>] a list of facet field names
    # @return [Array<Solr::Response::Facets::FacetField>]
    def facets_from_request(fields = facet_field_names)
      fields.map { |field| facet_by_field_name(field) }.compact
    end

    # @param group [String] a group name of facet fields
    # @return [Array<String>] a list of the facet field names from the configuration
    def facet_field_names(group = nil)
      blacklight_config.facet_fields.select { |_facet, opts| group == opts[:group] }.values.map(&:field)
    end

    def facet_group_names
      blacklight_config.facet_fields.map { |_facet, opts| opts[:group] }.uniq
    end

    # Get a FacetField object from the @response
    def facet_by_field_name(field_or_field_name)
      case field_or_field_name
      when String, Symbol
        facet_field = facet_configuration_for_field(field_or_field_name)
        @response.aggregations[facet_field.field]
      when Blacklight::Configuration::FacetField
        @response.aggregations[field_or_field_name.field]
      else
        # is this really a useful case?
        field_or_field_name
      end
    end
  end
end
