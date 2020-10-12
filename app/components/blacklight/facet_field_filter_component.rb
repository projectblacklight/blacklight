# frozen_string_literal: true

module Blacklight
  class FacetFieldFilterComponent < ::ViewComponent::Base
    def initialize(facet_field:)
      @facet_field = facet_field
    end

    def render?
      @facet_field.facet_field.index_range.any?
    end

    def prefix
      @facet_field.paginator.prefix
    end

    def clear_facet_prefix_url
      @facet_field.paginator.params_for_resort_url('index', @facet_field.search_state.to_h.except(@facet_field.paginator.request_keys[:prefix]))
    end

    def facet_prefix_url(letter)
      @facet_field.paginator.params_for_resort_url('index', @facet_field.search_state.to_h.merge(@facet_field.paginator.request_keys[:prefix] => letter))
    end
  end
end
