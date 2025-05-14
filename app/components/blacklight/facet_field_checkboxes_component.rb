# frozen_string_literal: true

module Blacklight
  class FacetFieldCheckboxesComponent < Facets::CheckboxesComponent; end
  FacetFieldCheckboxesComponent = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("FacetFieldCheckboxesComponent", "Blacklight::Facets::CheckboxesComponent", ActiveSupport::Deprecation.new)
end
