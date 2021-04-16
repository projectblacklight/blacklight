# frozen_string_literal: true

module Blacklight
  class DocumentTitleComponent < ::ViewComponent::Base
    renders_many :before_title
    renders_many :after_title
    renders_many :actions

    # rubocop:disable Metrics/ParameterLists
    def initialize(title = nil, document: nil, presenter: nil, as: :h3, counter: nil, classes: 'index_title document-title-heading col', link_to_document: true, document_component: nil)
      raise ArgumentError, 'missing keyword: :document or :presenter' if presenter.nil? && document.nil?

      @title = title
      @document = document
      @presenter = presenter
      @as = as || :h3
      @counter = counter
      @classes = classes
      @link_to_document = link_to_document
      @document_component = document_component
    end
    # rubocop:enable Metrics/ParameterLists

    # Content for the document title area; should be an inline element
    def title
      if @link_to_document
        @view_context.link_to_document presenter.document, @title.presence || content.presence, counter: @counter, itemprop: 'name'
      else
        content_tag('span', @title.presence || content.presence || presenter.heading, itemprop: 'name')
      end
    end

    # Content for the document actions area
    def actions
      if block_given?
        @has_actions_slot = true
        return super
      end

      (@has_actions_slot && get_slot(:actions)) ||
        ([@document_component&.actions] if @document_component&.actions.present?) ||
        [@view_context.render_index_doc_actions(presenter.document, wrapping_class: 'index-document-functions col-sm-3 col-lg-2')]
    end

    def counter
      return unless @counter

      content_tag :span, class: 'document-counter' do
        t('blacklight.search.documents.counter', counter: @counter)
      end
    end

    private

    def presenter
      @presenter ||= @view_context.document_presenter(@document)
    end
  end
end
