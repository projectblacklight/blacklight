# frozen_string_literal: true

module Blacklight
  class FacetItemComponent < Facets::ItemComponent; end
  FacetItemComponent = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("FacetItemComponent", "Blacklight::Facets::ItemComponent", ActiveSupport::Deprecation.new)
end
