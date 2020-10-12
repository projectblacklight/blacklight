# frozen_string_literal: true

module Blacklight
  class ConstraintComponent < ::ViewComponent::Base
    with_collection_parameter :facet_item_presenter

    def initialize(facet_item_presenter:, classes: 'filter', layout: Blacklight::ConstraintLayoutComponent)
      @facet_item_presenter = facet_item_presenter
      @classes = classes
      @layout = layout
    end
  end
end
