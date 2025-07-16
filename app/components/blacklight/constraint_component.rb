# frozen_string_literal: true

module Blacklight
  class ConstraintComponent < Blacklight::Component
    with_collection_parameter :facet_item_presenter

    # @param [Blacklight::FacetItemPresenter] facet_item_presenter
    # @param [Array<String>] classes
    # @param [Blacklight::ConstraintLayoutComponent] layout
    def initialize(facet_item_presenter:, classes: %w[filter mx-1], layout: Blacklight::ConstraintLayoutComponent)
      @facet_item_presenter = facet_item_presenter
      @classes = classes
      @layout = layout
    end

    attr_accessor :facet_item_presenter

    delegate :field_label, :constraint_label, :remove_href, to: :facet_item_presenter

    def classes
      @classes + ["filter-#{facet_item_presenter.key.parameterize}"]
    end
  end
end
