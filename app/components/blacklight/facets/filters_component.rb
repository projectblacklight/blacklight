# frozen_string_literal: true

module Blacklight::Facets
  class FiltersComponent < Blacklight::Component
    # @param [Blacklight::FacetFieldPresenter] presenter
    def initialize(presenter:, classes: 'facet-filters card card-body bg-light p-3 mb-3 border-0',
                   suggestions_component: Blacklight::Facets::SuggestComponent,
                   index_navigation_component: Blacklight::Facets::IndexNavigationComponent)
      @presenter = presenter
      @classes = classes
      @suggestions_component = suggestions_component
      @index_navigation_component = index_navigation_component
    end

    def facet
      @presenter.facet_field
    end

    attr_reader :classes, :presenter, :suggestions_component, :index_navigation_component

    delegate :display_facet, to: :presenter

    def render?
      facet.suggest != false || render_index_navigation?
    end

    def render_index_navigation?
      facet.index_range && display_facet.index?
    end

    def suggestions
      render suggestions_component.new(presenter: presenter)
    end

    def index_navigation
      render index_navigation_component.new(presenter: presenter)
    end
  end
end
