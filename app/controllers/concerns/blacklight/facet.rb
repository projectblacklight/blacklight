# frozen_string_literal: true
module Blacklight
  # These are methods that are used at both the view helper and controller layers
  # They are only dependent on `blacklight_config` and `@response`
  #
  module Facet
    def facet_paginator(field_config, display_facet)
      blacklight_config.facet_paginator_class.new(
        display_facet.items,
        sort: display_facet.sort,
        offset: display_facet.offset,
        prefix: display_facet.prefix,
        limit: facet_limit_for(field_config.key)
      )
    end

    def facets_from_request(fields = facet_field_names)
      fields.map { |field| facet_by_field_name(field) }.compact
    end

    def facet_field_names
      blacklight_config.facet_fields.values.map(&:field)
    end

    # @param [String] field Solr facet name
    # @return [Blacklight::Configuration::FacetField] Blacklight facet configuration for the solr field
    def facet_configuration_for_field(field)
      # short-circuit on the common case, where the solr field name and the blacklight field name are the same.
      return blacklight_config.facet_fields[field] if blacklight_config.facet_fields[field] && blacklight_config.facet_fields[field].field == field

      # Find the facet field configuration for the solr field, or provide a default.
      blacklight_config.facet_fields.values.find { |v| v.field.to_s == field.to_s } ||
        Blacklight::Configuration::FacetField.new(field: field).normalize!
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
