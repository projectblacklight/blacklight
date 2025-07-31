# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class BookmarkComponent < Blacklight::Component
      # @param [Blacklight::Document] document
      # @param [Blacklight::Configuration::ToolConfig] action - only used to pass a key for the wrapping action.
      # @param [Boolean] checked
      # @param [Object] bookmark_path the rails route to use for bookmarks
      def initialize(document:, action: nil, checked: nil, bookmark_path: nil, **)
        @document = document
        @checked = checked
        @bookmark_path = bookmark_path
        @action = action
        super()
      end

      # Used by ActionsComponent
      def key
        @action&.key || :bookmark
      end

      def bookmarked?
        return @checked unless @checked.nil?

        helpers.bookmarked? @document
      end

      def bookmark_icon
        return unless helpers.blacklight_config.bookmark_icon_component

        render helpers.blacklight_config.bookmark_icon_component.new(name: 'bookmark')
      end

      def bookmark_path
        @bookmark_path || helpers.bookmark_path(@document)
      end
    end
  end
end
