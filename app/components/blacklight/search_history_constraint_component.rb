# frozen_string_literal: true

module Blacklight
  class SearchHistoryConstraintComponent < Blacklight::ConstraintComponent
    with_collection_parameter :facet_item_presenter

    def initialize(facet_item_presenter:, layout: Blacklight::SearchHistoryConstraintLayoutComponent, **options)
      super
    end
  end
end
