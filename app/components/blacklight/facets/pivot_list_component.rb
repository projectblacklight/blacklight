# frozen_string_literal: true

module Blacklight
  module Facets
    class PivotListComponent < Blacklight::Facets::ListComponent
      def initialize(facet_field:,
                     classes: %w[pivot-facet facet-values list-unstyled],
                     role: 'tree',
                     layout: nil)
        super
      end
    end
  end
end
