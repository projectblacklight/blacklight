# frozen_string_literal: true

# Constraints content
module Blacklight
  class ConstraintsContentComponent < Blacklight::Component
    def initialize(query_constraints_area:,
                   facet_constraints_area:,
                   additional_constraints:)
      @query_constraints_area = query_constraints_area,
                                @facet_constraints_area = facet_constraints_area,
                                @additional_constraints = additional_constraints
    end
  end
end
