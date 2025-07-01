# frozen_string_literal: true

module Blacklight
  module Facets
    class PivotListComponent < Blacklight::Facets::ListComponent
      def initialize(facet_field:, role: 'tree', layout: nil)
        super
      end
    end
  end
end
