# frozen_string_literal: true

module Blacklight
  module Response
    # Render a group of facet fields
    class FacetGroupComponent < Blacklight::Component
      renders_one :body

      # @param [Blacklight::Response] response
      # @param [Array<Blacklight::Configuration::FacetField>] fields facet fields to render
      # @param [String] title the title of the facet group section
      # @param [String] id a unique identifier for the group
      def initialize(id:, title: nil, fields: [], response: nil)
        @groupname = id
        @id = id ? "facets-#{id}" : 'facets'
        @title = title || I18n.t("blacklight.search.#{@id}.title")
        @panel_id = id ? "facet-panel-#{id}-collapse" : 'facet-panel-collapse'

        # deprecated variables
        @fields = fields
        @response = response
      end

      def render?
        body.present?
      end
    end
  end
end
