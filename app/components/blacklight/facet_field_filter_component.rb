# frozen_string_literal: true

module Blacklight
  class FacetFieldFilterComponent < Facets::IndexNavigationComponent
    def initialize(...)
      Rails.logger.warn("Blacklight::FacetFieldFilterComponent is deprecated. Use Blacklight::Facets::IndexNavigationComponent instead.")
      super
    end
  end
end
