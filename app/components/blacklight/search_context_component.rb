# frozen_string_literal: true

module Blacklight
  class SearchContextComponent < Blacklight::Component
    with_collection_parameter :search_context

    def initialize(search_context:, search_session:)
      @search_context = search_context
      @search_session = search_session
    end

    def render?
      @search_context.present? && (@search_context[:prev] || @search_context[:next])
    end

    def item_page_entry_info
      Deprecation.silence(Blacklight::CatalogHelperBehavior) do
        helpers.item_page_entry_info
      end
    end

    def link_to_previous_document(*args)
      Deprecation.silence(Blacklight::UrlHelperBehavior) do
        helpers.link_to_previous_document(*args)
      end
    end

    def link_to_next_document(*args)
      Deprecation.silence(Blacklight::UrlHelperBehavior) do
        helpers.link_to_next_document(*args)
      end
    end
  end
end
