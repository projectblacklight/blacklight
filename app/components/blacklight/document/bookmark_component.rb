# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class BookmarkComponent < ::ViewComponent::Base
      # @param [Blacklight::Document] document
      # @param [Boolean] checked
      # @param [Object] bookmark_path the rails route to use for bookmarks
      def initialize(document:, checked: nil, bookmark_path: nil)
        @document = document
        @checked = checked
        @bookmark_path = bookmark_path
      end

      def bookmarked?
        return @checked unless @checked.nil?

        @view_context.bookmarked? @document
      end

      def bookmark_path
        @bookmark_path || @view_context.bookmark_path(@document)
      end
    end
  end
end
