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
      solr_parameters[:fq] ||= []
      bookmarks = @scope.context.fetch(:bookmarks)
      return unless bookmarks

      document_ids = bookmarks.collect { |b| b.document_id.to_s }
      solr_parameters[:fq] += ["{!terms f=id}#{document_ids.join(',')}"]
    end
    self.default_processor_chain += [:bookmarked]
  end
end
