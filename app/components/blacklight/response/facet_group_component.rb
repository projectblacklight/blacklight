# frozen_string_literal: true

module Blacklight
  module Response
    class FacetGroupComponent < ::ViewComponent::Base
      def initialize(response:, fields: [], title: nil, id: nil)
        @response = response
        @fields = fields
        @title = title
        @id = id ? "facets-#{id}" : 'facets'
        @panel_id = id ? "facet-panel-#{id}-collapse" : 'facet-panel-collapse'
      end

      def render?
        @view_context.has_facet_values?(@fields, @response)
      end
    end
  end
end
