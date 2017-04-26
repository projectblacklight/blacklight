module Blacklight
  class BookmarksListPresenter
    # @param list [Array<SolrDocument>] list of bookmarks
    # @param view_context [#blacklight_config] the blacklight configuration
    def initialize(list, view_context)
      @bookmarks = list
      @view_context = view_context
    end

    attr_reader :view_context

    # TODO: Extract to Blacklight::ListPresenter (along with ResultsPagePresenter)
    # Return a row presenter for the given document
    def item_presenter_for(document)
      item_presenter_class.new(document, view_context)
    end

    private

    # The presenter class for each result on the page
    def item_presenter_class
      configuration.index.document_presenter_class
    end

    def configuration
      @view_context.blacklight_config
    end
  end
end
