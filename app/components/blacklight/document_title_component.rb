# frozen_string_literal: true

module Blacklight
  class DocumentTitleComponent < Blacklight::Component
    renders_many :before_titles
    renders_many :after_titles

    # rubocop:disable Metrics/ParameterLists
    def initialize(title = nil, presenter:, as: :h3, counter: nil, classes: 'index_title document-title-heading col h5', link_to_document: true, document_component: nil)
      @title = title
      @presenter = presenter
      @as = as || :h3
      @counter = counter
      @classes = classes
      @link_to_document = link_to_document
      @document_component = document_component
      @document = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(@presenter.document,
                                                                        "Don't use the @document instance variable. Instead use @presenter",
                                                                        ActiveSupport::Deprecation.new)
    end
    # rubocop:enable Metrics/ParameterLists

    attr_accessor :presenter

    # Content for the document title area; should be an inline element
    def title
      if @link_to_document
        helpers.link_to_document presenter.document, @title.presence || content.presence, counter: @counter, itemprop: 'name'
      else
        content_tag('span', @title.presence || content.presence || presenter.heading, itemprop: 'name')
      end
    end

    def counter
      return unless @counter

      content_tag :span, class: 'document-counter' do
        t('blacklight.search.documents.counter', counter: @counter)
      end
    end
  end
end
