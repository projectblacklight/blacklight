# frozen_string_literal: true

module Blacklight
  class FacetFieldNoLayoutComponent < Facets::NoLayoutComponent; end
  FacetFieldNoLayoutComponent = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("FacetFieldNoLayoutComponent", "Blacklight::Facets::NoLayoutComponent", ActiveSupport::Deprecation.new)
end
