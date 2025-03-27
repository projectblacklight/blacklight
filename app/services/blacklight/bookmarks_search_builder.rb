# frozen_string_literal: true

module Blacklight
  # Extends the search Builders to add bookmarks
  class BookmarksSearchBuilder < ::SearchBuilder
    ##
    # Filters the query to only include the bookmarked items
    #
    # @param [Hash] solr_parameters
    #
    # @return [void]
    def bookmarked(solr_parameters)
      bookmarks = @scope.context.fetch(:bookmarks)
      return unless bookmarks

      document_ids = bookmarks.collect { |b| b.document_id.to_s }
      limit_to_specific_records(solr_parameters, document_ids)
    end
    self.default_processor_chain += [:bookmarked]
  end
end
