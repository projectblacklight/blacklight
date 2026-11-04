# frozen_string_literal: true

module Blacklight
  # Derives open graph metadata tags for a document
  class OpenGraphPresenter
    # @param [Blacklight::DocumentPresenter] document_presenter
    def initialize(document_presenter)
      @presenter = document_presenter
    end

    attr_reader :presenter

    delegate :document, :view_context, :configuration, to: :presenter

    # Hash of property:content pairs that will become <meta> tags
    def properties
      {
        'og:type' => type,
        'og:title' => title,
        'og:description' => description,
        'og:image' => image
      }.compact_blank
    end

    def type = 'website'
    def title = presenter.html_title
    def description = nil

    def image
      url = presenter.thumbnail.url
      view_context.image_url(url) if url
    end
  end
end
