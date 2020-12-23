# frozen_string_literal: true
module Blacklight
  # These are methods that are used at both the view helper and controller layers
  # They are only dependent on `blacklight_config` and `@response`
  #
  module Facet
    extend Deprecation
    delegate :facet_configuration_for_field, :facet_field_names, to: :blacklight_config
    delegate :facet_group_names, to: :blacklight_config
    deprecation_deprecate facet_group_names: 'Use blacklight_config.facet_group_names instead'

    # Get a FacetField object from the @response
    # @deprecated
    # @private
    # @return [Blacklight::Solr::Response::Facets::FacetField]
    def facet_by_field_name(field_or_field_name, response = nil)
      unless response
        Deprecation.warn(self, 'Calling facet_by_field_name without passing the ' \
          'second argument (response) is deprecated and will be removed in Blacklight ' \
          '8.0.0')
        response = @response
      end
      case field_or_field_name
      when String, Symbol
        facet_field = facet_configuration_for_field(field_or_field_name)
        response.aggregations[facet_field.field]
      when Blacklight::Configuration::FacetField
        response.aggregations[field_or_field_name.field]
      else
        # is this really a useful case?
        field_or_field_name
      end
    end
    deprecation_deprecate facet_by_field_name: 'Removed without replacement'
  end
end
