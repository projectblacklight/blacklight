# frozen_string_literal: true

module Blacklight
  class SearchButtonComponent < Blacklight::Component
    def initialize(text:, id:)
      @text = text
      @id = id
    end

    def call
      tag.button(class: 'btn btn-primary search-btn', type: 'submit', id: @id, aria: { label: @text }) do
        tag.span(@text, class: "d-none d-md-inline me-sm-1 submit-search-text", aria: { hidden: true }) +
          render(Blacklight::Icons::SearchComponent.new)
      end
    end
  end
end
