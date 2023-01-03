# frozen_string_literal: true

module Blacklight
  module SearchContext
    class ClientItemPaginationComponent < Blacklight::Component
      delegate :search_action_path, to: :helpers

      def initialize(counter:, **_args)
        @counter = counter
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

      def link_to_previous_document(classes: 'previous', **link_opts)
        # rubocop:disable Rails/OutputSafety
        link_opts = { class: classes, rel: 'prev' }.merge(link_opts)
        link_to '#', link_opts do
          tag.span raw(t('views.pagination.previous')), class: 'previous'
        end
        # rubocop:enable Rails/OutputSafety
      end

      def link_to_next_document(classes: 'next', **link_opts)
        # rubocop:disable Rails/OutputSafety
        link_opts = { class: classes, rel: 'next' }.merge(link_opts)
        link_to '#', link_opts do
          tag.span raw(t('views.pagination.next')), class: 'next'
        end
        # rubocop:enable Rails/OutputSafety
      end
    end
  end
end
