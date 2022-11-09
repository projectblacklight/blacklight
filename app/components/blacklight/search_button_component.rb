# frozen_string_literal: true

module Blacklight
  class SearchButtonComponent < ::ViewComponent::Base
    def initialize(text:, id:)
      @text = text
      @id = id
    end

    def call
      tag.button(class: 'btn btn-primary search-btn', type: 'submit', id: @id) do
        tag.span(@text, class: "submit-search-text") +
          blacklight_icon(:search, aria_hidden: true)
      end
    end
  end
end
