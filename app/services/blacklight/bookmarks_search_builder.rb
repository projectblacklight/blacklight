# frozen_string_literal: true

module Blacklight
  # Extends the search Builders to add bookmarks
  class BookmarksSearchBuilder < ::SearchBuilder
    ##
    # Filters the query to only include the bookmarked items
    #
    # @param [Blacklight::Solr::Request, Blacklight::ElasticSearch::Request] request_parameters
    #
    # @return [void]
    def bookmarked(request_parameters)
      bookmarks = @scope.context.fetch(:bookmarks)
      return unless bookmarks

      document_ids = bookmarks.collect { |b| b.document_id.to_s }
      request_parameters.append_ids_filter(blacklight_config.document_model.unique_key, document_ids)
    end
    self.default_processor_chain += [:bookmarked]
  end
end
