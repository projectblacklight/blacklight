# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class BookmarkComponent < Blacklight::Component
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

        helpers.bookmarked? @document
      end

      def bookmark_path
        @bookmark_path || helpers.bookmark_path(@document)
      end

      def present_label
        @present_label ||= t('blacklight.search.bookmarks.present')
      end

      def absent_label
        @absent_label ||= t('blacklight.search.bookmarks.absent')
      end

      def checkbox
        label = bookmarked? ? present_label : absent_label
        tag.div data: {
          controller: "blacklight-bookmark",
          blacklight_bookmark_present_value: present_label,
          blacklight_bookmark_absent_value: absent_label,
          blacklight_bookmark_inprogress_value: t('blacklight.search.bookmarks.inprogress'),
          blacklight_bookmark_url_value: bookmark_path
        } do
          safe_join(
            [
              check_box_tag(checkbox_id, @document.id, bookmarked?,
                            data: {
                              action: "click->blacklight-bookmark#toggle",
                              blacklight_bookmark_target: "checkbox"
                            }),
              label_tag(checkbox_id, label, data: { blacklight_bookmark_target: "label" })
            ],
            ' '
          )
        end
      end

      def checkbox_id
        @checkbox_id ||= "bookmark_#{@document.id.to_s.parameterize}"
      end
    end
  end
end
