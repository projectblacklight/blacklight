# frozen_string_literal: true

module Blacklight
  class FacetFieldInclusiveConstraintComponent < Facets::InclusiveConstraintComponent
    def initialize(...)
      Rails.logger.warn("Blacklight::FacetFieldInclusiveConstraintComponent is deprecated. Use Blacklight::Facets::InclusiveConstraintComponent instead.")
      super
    end
  end
end
