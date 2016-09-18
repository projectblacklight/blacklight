module Blacklight
  class ResultsPagePresenter
    def initialize(response, view_context)
      @response = response
      @view_context = view_context
    end

    delegate :empty?, to: :@response
    
    def facets
      @facets_presenter ||= Blacklight::FacetListPresenter.new(@response, @view_context)
    end
  end
end
