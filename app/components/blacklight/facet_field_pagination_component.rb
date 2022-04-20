# frozen_string_literal: true

module Blacklight
  class FacetFieldPaginationComponent < Blacklight::Component
    def initialize(facet_field:)
      @facet_field = facet_field
    end

    def sort_facet_url(sort)
      @facet_field.paginator.params_for_resort_url(sort, @facet_field.search_state.to_h)
    end

    def param_name
      @facet_field.paginator.class.request_keys[:page]
    end

    def render?
      @facet_field.paginator
    end
  end
end
