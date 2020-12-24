# frozen_string_literal: true

module Blacklight
  class SearchContextComponent < ::ViewComponent::Base
    with_collection_parameter :search_context

    def initialize(search_context:, search_session:)
      @search_context = search_context
      @search_session = search_session
    end

    def render?
      @search_context.present? && (@search_context[:prev] || @search_context[:next])
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

    def link_to_previous_document(previous_document)
      link_opts = helpers.session_tracking_params(previous_document, count - 1, per_page: per_page, search_id: search_id)
                         .merge(class: "previous", rel: 'prev')
      link_to_unless previous_document.nil?, raw(t('views.pagination.previous')), helpers.search_state.url_for_document(previous_document), link_opts do
        tag.span raw(t('views.pagination.previous')), class: 'previous'
      end
    end

    def link_to_next_document(next_document)
      link_opts = helpers.session_tracking_params(next_document, count + 1, per_page: per_page, search_id: search_id)
                         .merge(class: "next", rel: 'next')
      link_to_unless next_document.nil?, raw(t('views.pagination.next')), helpers.search_state.url_for_document(next_document), link_opts do
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
      controller.current_search_session&.id
    end
  end
end
