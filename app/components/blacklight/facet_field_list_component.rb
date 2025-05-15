# frozen_string_literal: true

module Blacklight
  class FacetFieldListComponent < Facets::ListComponent; end
  FacetFieldListComponent = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("FacetFieldListComponent", "Blacklight::Facets::ListComponent", ActiveSupport::Deprecation.new)
end
