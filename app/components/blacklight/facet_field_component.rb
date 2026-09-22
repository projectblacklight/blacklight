# frozen_string_literal: true

module Blacklight
  class FacetFieldComponent < Facets::FieldComponent
    def initialize(...)
      Rails.logger.warn("Blacklight::FacetFieldComponent is deprecated. Use Blacklight::Facets::FieldComponent instead.")
      super
    end
  end
end
