# frozen_string_literal: true

module Blacklight
  class FacetFieldInclusiveConstraintComponent < Blacklight::Component
    with_collection_parameter :facet_field

    def initialize(facet_field:, values: nil)
      @facet_field = facet_field
      @values = values
    end

    def values
      @values ||= @facet_field.values.find { |v| v.is_a? Array }
      @values || []
    end

    def render?
      values.present?
    end

    def presenters
      return to_enum(:presenters) unless block_given?

      values.each do |item|
        yield Blacklight::FacetGroupedItemPresenter.new(values, item, @facet_field.facet_field, helpers, @facet_field.key, @facet_field.search_state)
      end
    end
  end
end
