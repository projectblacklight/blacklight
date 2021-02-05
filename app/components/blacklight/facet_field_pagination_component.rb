# frozen_string_literal: true

module Blacklight
  class FacetFieldPaginationComponent < ::ViewComponent::Base
    def initialize(facet_field:)
      @facet_field = facet_field
    end

    def sort_facet_url(sort)
      @facet_field.paginator.params_for_resort_url(sort, @facet_field.search_state.to_h)
    end

    def param_name
      @facet_field.paginator.class.request_keys[:page]
    end
  end
end
