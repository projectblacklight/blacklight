# frozen_string_literal: true

module Blacklight
  class FacetFieldComponent < Facets::FieldComponent; end
  FacetFieldComponent = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("FacetFieldComponent", "Blacklight::Facets::FieldComponent", ActiveSupport::Deprecation.new)
end
