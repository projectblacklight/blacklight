# frozen_string_literal: true

module Blacklight::Facets
  class FiltersComponent < Blacklight::Component
    # @param [Blacklight::FacetFieldPresenter] presenter
    def initialize(presenter:, classes: 'facet-filters card card-body bg-light p-3 mb-3 border-0')
      @presenter = presenter
      @classes = classes
    end

    def facet
      @presenter.facet_field
    end

    attr_reader :classes, :presenter

    delegate :display_facet, to: :presenter

    def render?
      facet.suggest != false || render_index_navigation?
    end

    def render_index_navigation?
      facet.index_range && display_facet.index?
    end
  end
end
