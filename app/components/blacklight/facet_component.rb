# frozen_string_literal: true

module Blacklight
  ##
  # Renders a single section for facet limit with a specified
  # solr field used for faceting. This renders no UI of it's own, but renders
  # the component that is configured for the facet.
  class FacetComponent < ViewComponent::Base
    with_collection_parameter :display_facet

    # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
    # @param [Blacklight::Configuration] blacklight_config
    # @param [Boolean] layout
    def initialize(display_facet:, blacklight_config:, layout: true)
      @display_facet = display_facet
      @field_config = blacklight_config.facet_configuration_for_field(@display_facet.name)
      @layout = layout
    end

    def render?
      helpers.should_render_field?(@field_config, @display_facet)
    end

    def call
      component = @field_config.component.presence || Blacklight::FacetFieldListComponent

      render(
        component.new(
          facet_field: helpers.facet_field_presenter(@field_config, @display_facet),
          layout: @layout
        )
      )
    end
  end
end
