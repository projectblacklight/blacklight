# frozen_string_literal: true

module Blacklight
  class FacetFieldInclusiveConstraintComponent < Facets::InclusiveConstraintComponent; end
  FacetFieldInclusiveConstraintComponent = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("FacetFieldInclusiveConstraintComponent",
                                                                                                   "Blacklight::Facets::InclusiveConstraintComponent",
                                                                                                   ActiveSupport::Deprecation.new)
end
