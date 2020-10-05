# frozen_string_literal: true

module Blacklight
  module Document
    class BookmarkComponent < ::ViewComponent::Base
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
