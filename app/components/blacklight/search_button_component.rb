# frozen_string_literal: true

module Blacklight
  class SearchButtonComponent < Blacklight::Component
    def initialize(text:, id:)
      @text = text
      @id = id
    end

    def call
      tag.button(class: 'btn btn-primary search-btn', type: 'submit', id: @id) do
        tag.span(@text, class: "visually-hidden-sm me-sm-1 submit-search-text") +
          render(Blacklight::Icons::SearchComponent.new)
      end
    end
  end
end
