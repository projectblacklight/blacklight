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

    def item_page_entry_info
      t('blacklight.search.entry_pagination_info.other', current: number_with_delimiter(@search_session['counter']),
                                                         total: number_with_delimiter(@search_session['total']),
                                                         count: @search_session['total'].to_i).html_safe
    end

    ##
    # Link to the previous document in the current search context
    def link_to_previous_document(previous_document)
      previous_document = @search_context[:prev]

      link_opts = session_tracking_params(previous_document, @search_session['counter'].to_i - 1).merge(class: "previous", rel: 'prev')
      link_to_unless previous_document.nil?, raw(t('views.pagination.previous')), url_for_document(previous_document), link_opts do
        tag.span raw(t('views.pagination.previous')), class: 'previous'
      end
    end

    ##
    # Link to the next document in the current search context
    def link_to_next_document
      next_document = @search_context[:next]

      link_opts = session_tracking_params(next_document, @search_session['counter'].to_i + 1).merge(class: "next", rel: 'next')
      link_to_unless next_document.nil?, raw(t('views.pagination.next')), url_for_document(next_document), link_opts do
        tag.span raw(t('views.pagination.next')), class: 'next'
      end
    end
  end
end
