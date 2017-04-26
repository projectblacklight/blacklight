module Blacklight
  class BookmarksListPresenter
    # @param list [Array<SolrDocument>] list of bookmarks
    # @param view_context [#blacklight_config] the blacklight configuration
    def initialize(list, view_context)
      @bookmarks = list
      @view_context = view_context
    end

    # The presenter class for each result on the page
    def presenter_class
      configuration.index.document_presenter_class
    end

    private

    def configuration
      @view_context.blacklight_config
    end
  end
end
