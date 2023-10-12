# frozen_string_literal: true

module Blacklight
  # Override the default item presenter to provide custom labels for
  # range data.
  class FacetItemRangePresenter < Blacklight::FacetItemPresenter
    # Overriding method to generate a more descriptive label
    def label
      label_for_range || super
    end

    private

    def label_for_range
      return unless value.is_a? Range

      view_context.t(range_limit_label_key, start: value.first, end: value.last)
    end

    def range_limit_label_key
      if value.first == value.last
        'blacklight.search.facets.range.single_value'
      else
        'blacklight.search.facets.range.range_value'
      end
    end
  end
end
