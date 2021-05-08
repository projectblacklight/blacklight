# frozen_string_literal: true

module Blacklight
  module Response
    # Render a group of facet fields
    class FacetGroupComponent < ::ViewComponent::Base
      # @param [Blacklight::Response] response
      # @param [Array<Blacklight::Configuration::FacetField>] fields facet fields to render
      # @param [String] title the title of the facet group section
      # @param [String] id a unique identifier for the group
      def initialize(response:, fields: [], title: nil, id: nil)
        @response = response
        @fields = fields
        @title = title
        @id = id ? "facets-#{id}" : 'facets'
        @panel_id = id ? "facet-panel-#{id}-collapse" : 'facet-panel-collapse'
      end

      def render?
        search_facets.any? { |display_facet| should_render_facet?(display_facet) }
      end

      # @return [Array<Blacklight::Solr::Response::Facets::FacetField>]
      def search_facets
        @fields.map { |field| @response.aggregations[field.field] }.compact
      end

      delegate :blacklight_config, to: :helpers

      ##
      # Determine if Blacklight should render the display_facet or not
      #
      # By default, only render facets with items.
      #
      # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
      # @return [Boolean]
      def should_render_facet? display_facet
        return false if display_facet.items.blank?

        helpers.should_render_field?(facet_config_for(display_facet.name), display_facet)
      end

      def facet_config_for(name)
        @fields.select { |field| field.field == name }
      end
    end
  end
end
