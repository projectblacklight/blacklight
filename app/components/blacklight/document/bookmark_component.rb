# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class BookmarkComponent < Blacklight::Component
      # @param [Blacklight::Document] document
      # @param [Blacklight::Configuration::ToolConfig] action - only used to pass a key for the wrapping action.
      # @param [Boolean] checked whether the document is bookmarked; takes precedence over bookmarks
      # @param [Enumerable<Bookmark>, nil] bookmarks the current user's bookmarks (e.g. for all documents on the page);
      #   if neither this nor checked is provided, the bookmarks are looked up for the current page
      # @param [Object] bookmark_path the rails route to use for bookmarks
      def initialize(document:, action: nil, checked: nil, bookmarks: nil, bookmark_path: nil, **)
        @document = document
        @checked = checked
        @bookmarks = bookmarks
        @bookmark_path = bookmark_path
        @action = action
        super()
      end

      # Used by ActionsComponent
      def key
        @action&.key || :bookmark
      end

      # Check if the document is in the user's bookmarks
      # Note: we do string comparison of the classes, because hot reloading in the development environment may cause each to have
      #       separate versions of the class loaded (see document.class.object_id and Bookmark#document_type.object_id)
      # @return [Boolean]
      def bookmarked?
        return @checked unless @checked.nil?
        return @bookmarked if defined?(@bookmarked)

        # Backwards compatibility: respect applications that have overridden the (deprecated) helper method
        return @bookmarked = helpers.bookmarked?(@document) if @bookmarks.nil? && bookmarked_helper_overridden?

        @bookmarked = bookmarks.any? { |x| x.document_id == @document.id && x.document_type.to_s == @document.class.to_s }
      end

      def bookmark_icon
        return unless helpers.blacklight_config.bookmark_icon_component

        render helpers.blacklight_config.bookmark_icon_component.new(name: 'bookmark')
      end

      def bookmark_path
        @bookmark_path || helpers.bookmark_path(@document)
      end

      private

      def bookmarks
        @bookmarks ||= helpers.send(:current_bookmarks)
      end

      def bookmarked_helper_overridden?
        helpers.respond_to?(:bookmarked?) && helpers.method(:bookmarked?).owner != Blacklight::DocumentHelperBehavior
      end
    end
  end
end
