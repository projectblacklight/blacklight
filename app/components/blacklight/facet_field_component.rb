# frozen_string_literal: true

module Blacklight
  class FacetFieldComponent < ::ViewComponent::Base
    include Blacklight::ContentAreasShim

    renders_one :label
    renders_one :body

    def initialize(facet_field:)
      @facet_field = facet_field
    end
  end
end
