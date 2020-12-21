# frozen_string_literal: true

module Blacklight
  module Response
    # Render a group of facet fields
    class FacetGroupComponent < ::ViewComponent::Base
      # @param [Blacklight::Response] response
      # @param [Array<String>] fields facet fields to render
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
        Deprecation.silence(Blacklight::FacetsHelperBehavior) do
          Deprecation.silence(Blacklight::Facet) do
            helpers.facets_from_request(@fields, @response).any? { |display_facet| should_render_facet?(display_facet) }
          end
        end
      end

      ##
      # Render a collection of facet fields.
      # @see #render_facet_limit
      #
      # @param [Array<String>] fields
      # @param [Hash] options
      # @option options [Blacklight::Solr::Response] :response the Solr response object
      # @return String
      def render_facet_partials _fields = nil, _options = {}
        Deprecation.silence(Blacklight::FacetsHelperBehavior) do
          Deprecation.silence(Blacklight::Facet) do
            safe_join(helpers.facets_from_request(@fields, @response).map do |display_facet|
              helpers.render_facet_limit(display_facet)
            end.compact, "\n")
          end
        end
      end

      ##
      # Determine if Blacklight should render the display_facet or not
      #
      # By default, only render facets with items.
      #
      # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
      # @return [Boolean]
      def should_render_facet? display_facet
        return false if display_facet.items.blank?

        helpers.should_render_field?(
          helpers.facet_configuration_for_field(display_facet.name),
          display_facet
        )
      end
    end
  end
end
