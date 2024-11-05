# frozen_string_literal: true

module Blacklight
  module SearchContext
    class ServerItemPaginationComponent < Blacklight::SearchContextComponent
      with_collection_parameter :search_context

      def initialize(search_context:, search_session:, current_document:)
        @search_context = search_context
        @search_session = search_session
        @current_document_id = current_document.id
      end
    end
  end
end
