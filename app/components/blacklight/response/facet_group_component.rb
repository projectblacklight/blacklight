# frozen_string_literal: true

module Blacklight
  module Response
    # Render a group of facet fields
    class FacetGroupComponent < Blacklight::Component
      renders_one :body

      # @param [String] id a unique identifier for the group
      # @param [String] title the title of the facet group section
      def initialize(id:, title: nil)
        @groupname = id
        @id = id ? "facets-#{id}" : 'facets'
        @title = title || I18n.t("blacklight.search.#{@id}.title")
        @panel_id = id ? "facet-panel-#{id}-collapse" : 'facet-panel-collapse'
      end

      def render?
        body.present?
      end
    end
  end
end
