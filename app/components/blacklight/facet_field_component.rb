# frozen_string_literal: true

module Blacklight
  class FacetFieldComponent < ::ViewComponent::Base
    with_content_areas :label, :body

    def initialize(facet_field:)
      @facet_field = facet_field
    end
  end
end
