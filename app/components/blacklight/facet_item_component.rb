# frozen_string_literal: true

module Blacklight
  class FacetItemComponent < Facets::ItemComponent
    def initialize(...)
      Rails.logger.warn("Blacklight::FacetItemComponent is deprecated. Use Blacklight::Facets::ItemComponent instead.")
      super
    end
  end
end
