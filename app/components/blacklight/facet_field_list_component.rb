# frozen_string_literal: true

module Blacklight
  class FacetFieldListComponent < Facets::ListComponent
    def initialize(...)
      Rails.logger.warn("Blacklight::FacetFieldListComponent is deprecated. Use Blacklight::Facets::ListComponent instead.")
      super
    end
  end
end
