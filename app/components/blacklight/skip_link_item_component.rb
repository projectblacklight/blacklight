# frozen_string_literal: true

module Blacklight
  class SkipLinkItemComponent < Blacklight::Component
    def initialize(text:, href:)
      @text = text
      @href = href
    end

    def call
      link_to @text, @href, class: link_classes
    end

    def link_classes
      'd-inline-flex py-2 px-3'
    end
  end
end
