# frozen_string_literal: true

module Blacklight
  class ConstraintPresenter
    def initialize(facet_item_presenter:, field_label:)
      @facet_item_presenter = facet_item_presenter
      @field_label = field_label
    end

    attr_accessor :facet_item_presenter, :field_label

    delegate :key, :remove_href, to: :facet_item_presenter

    # Get the displayable version of the facet's value for use
    # in e.g. the constraints widget
    #
    # @return [String]
    def constraint_label
      facet_item_presenter.label
    end
  end
end
