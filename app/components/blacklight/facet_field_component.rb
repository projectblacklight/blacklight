# frozen_string_literal: true

module Blacklight
  class FacetFieldComponent < ::ViewComponent::Base
    include Blacklight::ContentAreasShim

    renders_one :label
    renders_one :body

    # @param [Blacklight::FacetFieldPresenter] facet_field
    def initialize(facet_field:)
      @facet_field = facet_field
    end

    def html_id
      "facet-#{@facet_field.key.parameterize}"
    end

    def header_html_id
      "#{html_id}-header"
    end
  end
end
