module Blacklight
  class ResultsPagePresenter
    class_attribute :facet_list_presenter
    self.facet_list_presenter = Blacklight::FacetListPresenter

    def initialize(response, view_context)
      @response = response
      @view_context = view_context
    end

    delegate :empty?, to: :@response
    
    def facets
      @facets_presenter ||= facet_list_presenter.new(@response, @view_context)
    end
  end
end
