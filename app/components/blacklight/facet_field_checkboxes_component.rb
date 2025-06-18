# frozen_string_literal: true

module Blacklight
  class FacetFieldCheckboxesComponent < Facets::CheckboxesComponent
    def initialize(...)
      Rails.logger.warn("Blacklight::FacetFieldCheckboxesComponent is deprecated. Use Blacklight::Facets::CheckboxesComponent instead.")
      super
    end
  end
end
