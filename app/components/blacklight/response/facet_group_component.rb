# frozen_string_literal: true

module Blacklight
  module Response
    # Render a group of facet fields
    class FacetGroupComponent < Blacklight::Component
      renders_one :body

      # @param [String] id a unique identifier for the group
      # @param [String] title the title of the facet group section
      def initialize(id:, title: nil, body_classes: 'facets-collapse d-lg-block collapse accordion',
                     header_classes: 'facets-heading h4',
                     container_classes: 'facets sidenav facets-toggleable-md')
        @groupname = id
        @id = id ? "facets-#{id}" : 'facets'
        @title = title || I18n.t("blacklight.search.#{@id}.title")
        @panel_id = id ? "facet-panel-#{id}-collapse" : 'facet-panel-collapse'
        @body_classes = body_classes
        @header_classes = header_classes
        @container_classes = container_classes
      end

      attr_accessor :body_classes, :header_classes, :container_classes

      def collapse_toggle_button(panel_id)
        render button_component.new(panel_id: panel_id)
      end

      def button_component
        Blacklight::Response::FacetToggleButtonComponent
      end

      def render?
        body.to_s.present?
      end
    end
  end
end
