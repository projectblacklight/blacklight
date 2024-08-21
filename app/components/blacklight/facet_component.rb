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
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists
    def initialize(display_facet_or_field_config: nil, display_facet: nil, field_config: nil, response: nil, blacklight_config: nil, component: nil, **component_args)
      if display_facet_or_field_config.is_a? Blacklight::FacetFieldPresenter
        @facet_field_presenter = display_facet_or_field_config
        @field_config = @facet_field_presenter.facet_field
        @display_facet = @facet_field_presenter.display_facet
      elsif display_facet_or_field_config.is_a?(Blacklight::Configuration::Field) || field_config
        @facet_field_presenter = nil # we need the view context to generate this
        @field_config = display_facet_or_field_config || field_config
        @display_facet = display_facet ||
                         response&.aggregations&.fetch(@field_config.field) { Blacklight::Solr::Response::Facets::NullFacetField.new(@field_config.field, response: response) }
      elsif (display_facet || display_facet_or_field_config).respond_to?(:name)
        @facet_field_presenter = nil # we need the view context to generate this
        @display_facet = display_facet || display_facet_or_field_config
        @field_config = field_config || blacklight_config&.facet_configuration_for_field(@display_facet.name)
      else
        raise ArgumentError, 'You must provide one of display_facet or field_config' unless @field_config
      end

      @component = component || @field_config.component
      @component_args = component_args
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists

    def render?
      helpers.should_render_field?(@field_config, @display_facet)
    end

    def call
      return render_partial if @field_config.partial

      render(
        @component.new(
          facet_field: @facet_field_presenter || helpers.facet_field_presenter(@field_config, @display_facet),
          **@component_args
        )
      )
    end

    def render_partial
      render(@field_config.partial, locals: { field_name: @field_config.field, facet_field: @field_config, display_facet: @display_facet }.merge(@component_args))
    end
  end
end
