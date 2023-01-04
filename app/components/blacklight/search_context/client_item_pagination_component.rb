# frozen_string_literal: true

module Blacklight
  module SearchContext
    class ClientItemPaginationComponent < Blacklight::Component
      delegate :search_action_path, to: :helpers

      def initialize(search_context:, **_args)
        @counter = search_context&.fetch(:counter, nil)
      end

      def render?
        @counter.present?
      end

      def page_links_url
        search_action_path action: 'page_links', counter: @counter
      end

      ##
      # Displays "showing X of Y items" message.
      #
      # @return [String]
      def item_page_entry_info
        # rubocop:disable Rails/OutputSafety
        t('blacklight.search.entry_pagination_info.other', current: "<span class=\"pagination-counter-delimited\"></span>",
                                                           total: "<span class=\"pagination-total-delimited\"></span>",
                                                           count: "<span class=\"pagination-total-raw\"></span>").html_safe
        # rubocop:enable Rails/OutputSafety
      end

      # Displays a stub link for previous document to be activated by client script
      # @return [String]
      def link_to_previous_document
        # rubocop:disable Rails/OutputSafety
        link_opts = { class: ['previous'], rel: 'prev', aria: { disabled: true } }
        content_tag :a, link_opts do
          tag.span raw(t('views.pagination.previous')), class: 'previous'
        end
        # rubocop:enable Rails/OutputSafety
      end

      # Displays a stub link for next document to be activated by client script
      # @return [String]
      def link_to_next_document
        # rubocop:disable Rails/OutputSafety
        link_opts = { class: ['next'], rel: 'next', aria: { disabled: true } }
        content_tag :a, link_opts do
          tag.span raw(t('views.pagination.next')), class: 'next'
        end
        # rubocop:enable Rails/OutputSafety
      end
    end
  end
end
