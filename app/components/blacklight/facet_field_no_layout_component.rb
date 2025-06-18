# frozen_string_literal: true

module Blacklight
  class FacetFieldNoLayoutComponent < Facets::NoLayoutComponent
    def initialize(...)
      Rails.logger.warn("Blacklight::FacetFieldNoLayoutComponent is deprecated. Use Blacklight::Facets::NoLayoutComponent instead.")
      super
    end
  end
end
