# frozen_string_literal: true

module Blacklight
  module Response
    # Render the button that shows or collapses the facets on a narrow viewport
    class FacetToggleButtonComponent < Blacklight::Component
      # @param [String] panel_id
      def initialize(panel_id:, classes: 'btn btn-outline-secondary btn-outline theme-secondary facet-toggle-button d-block d-lg-none lg:d-none')
        @panel_id = panel_id
        @classes = classes
      end
    end
  end
end
