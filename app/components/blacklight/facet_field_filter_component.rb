# frozen_string_literal: true

module Blacklight
  class FacetFieldFilterComponent < Facets::IndexNavigationComponent; end
  FacetFieldFilterComponent = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("FacetFieldFilterComponent", "Blacklight::Facets::IndexNavigationComponent", ActiveSupport::Deprecation.new)
end
