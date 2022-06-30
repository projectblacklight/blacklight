# frozen_string_literal: true

module Blacklight
  ##
  # Renders a single section for facet limit with a specified
  # solr field used for faceting. This renders no UI of it's own, but renders
  # the component that is configured for the facet.
  class FacetComponent < ViewComponent::Base
    with_collection_parameter :display_facet_or_field_config

    # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
    # @param [Blacklight::Configuration] blacklight_config
    # @param [Boolean] layout
    def initialize(display_facet_or_field_config: nil, display_facet: nil, field_config: nil, response: nil, blacklight_config: nil, **component_args)
      if display_facet_or_field_config.is_a?(Blacklight::Configuration::Field) || field_config
        @field_config = display_facet_or_field_config || field_config
        @display_facet = display_facet ||
                         response&.aggregations&.fetch(@field_config.field) { Blacklight::Solr::Response::Facets::NullFacetField.new(@field_config.field, response: response) }
      elsif (display_facet || display_facet_or_field_config).respond_to?(:name)
        @display_facet = display_facet || display_facet_or_field_config
        @field_config = field_config || blacklight_config&.facet_configuration_for_field(@display_facet.name)
      else
        raise ArgumentError, 'You must provide one of display_facet or field_config' unless @field_config
      end

      @component_args = component_args
    end

    def render?
      helpers.should_render_field?(@field_config, @display_facet)
    end

    def call
      return render_partial if @field_config.partial

      component = @field_config.component == true ? Blacklight::FacetFieldListComponent : @field_config.component

      render(
        component.new(
          facet_field: helpers.facet_field_presenter(@field_config, @display_facet),
          **@component_args
        )
      )
    end

    def render_partial
      helpers.render(@field_config.partial, locals: { field_name: @field_config.field, facet_field: @field_config, display_facet: @display_facet }.merge(@component_args))
    end
  end
end
