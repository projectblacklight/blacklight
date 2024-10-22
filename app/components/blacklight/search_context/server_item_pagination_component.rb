# frozen_string_literal: true

module Blacklight
  module SearchContext
    class ServerItemPaginationComponent < Blacklight::Component
      with_collection_parameter :search_context

      def initialize(search_context:, search_session:, current_document:)
        @search_context = search_context
        @search_session = search_session
        @current_document_id = current_document.id
      end

      def render?
        @search_context.present? && (@search_context[:prev] || @search_context[:next] || total.positive?) && (@search_session['document_id'] == @current_document_id)
      end

      ##
      # Displays "showing X of Y items" message.
      #
      # @return [String]
      def item_page_entry_info
        t('blacklight.search.entry_pagination_info.other', current: number_with_delimiter(count),
                                                           total: number_with_delimiter(total),
                                                           count: total).html_safe
      end

      def link_to_previous_document(previous_document = nil, classes: 'previous', **link_opts)
        previous_document ||= @search_context[:prev]
        link_opts = session_tracking_params(previous_document, count - 1, per_page: per_page, search_id: search_id).merge(class: classes, rel: 'prev').merge(link_opts)
        link_to_unless previous_document.nil?, raw(t('views.pagination.previous')), url_for_document(previous_document), link_opts do
          tag.span raw(t('views.pagination.previous')), class: 'previous'
        end
      end

      def link_to_next_document(next_document = nil, classes: 'next', **link_opts)
        next_document ||= @search_context[:next]
        link_opts = session_tracking_params(next_document, count + 1, per_page: per_page, search_id: search_id).merge(class: classes, rel: 'next').merge(link_opts)
        link_to_unless next_document.nil?, raw(t('views.pagination.next')), url_for_document(next_document), link_opts do
          tag.span raw(t('views.pagination.next')), class: 'next'
        end
      end

      private

      def count
        @search_session['counter'].to_i
      end

      def per_page
        @search_session['per_page']
      end

      def total
        @search_session['total'].to_i
      end

      def search_id
        @search_session['id'] || helpers.current_search_session&.id
      end

      def session_tracking_params(...)
        helpers.session_tracking_params(...)
      end

      def url_for_document(...)
        helpers.search_state.url_for_document(...)
      end
    end
  end
end
