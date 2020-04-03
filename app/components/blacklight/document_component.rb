# frozen_string_literal: true

module Blacklight
  class DocumentComponent < ::ViewComponent::Base
    # Available content areas; some have defaults provided by
    # the accessors below.
    with_content_areas :header, :body, :footer,
                       :before_title, :title, :after_title,
                       :actions, :metadata, :thumbnail,
                       :partials
    with_collection_parameter :document

    # rubocop:disable Metrics/ParameterLists
    # @param document [Blacklight::Document]
    # @param presenter [Blacklight::DocumentPresenter]
    # @param id [String] HTML id for the root element
    # @param classes [Array, String] additional HTML classes for the root element
    # @param component [Symbol, String] HTML tag type to use for the root element
    # @param title_component [Symbol, String] HTML tag type to use for the title element
    # @param metadata_component [Blacklight::DocumentMetadataComponent]
    # @param counter [Number, nil]
    # @param show [Boolean] are we showing only a single document (vs a list of search results); used for backwards-compatibility
    def initialize(document: nil, presenter: nil, id: nil, classes: [], component: :article, title_component: :h4, metadata_component: Blacklight::DocumentMetadataComponent, counter: nil, show: false)
      if presenter.nil? && document.nil?
        raise ArgumentError, 'missing keyword: :document or :presenter'
      end

      @document = document || presenter&.document
      @presenter = presenter

      @component = component
      @title_component = title_component
      @id = id || ('document' if show)
      @classes = classes

      @metadata_component = metadata_component

      @counter = counter

      @show = show
    end
    # rubocop:enable Metrics/ParameterLists

    # HTML classes to apply to the root element
    def classes
      [
        @classes,
        @view_context.render_document_class(@document),
        'document',
        ("document-position-#{@counter}" if @counter)
      ].compact.flatten
    end

    # Content for the document title area; should be an inline element
    def title
      @title || begin
        if show?
          content_tag('span', presenter.heading, itemprop: "name")
        else
          @view_context.link_to_document @document, counter: @counter, itemprop: 'name'
        end
      end
    end

    # Content for the document actions area
    def actions
      return if @show

      @actions || begin
        @view_context.render_index_doc_actions @document, wrapping_class: "index-document-functions col-sm-3 col-lg-2"
      end
    end

    # Content for the document thumbnail area
    def thumbnail
      return if @show

      @thumbnail || begin
        return unless presenter.thumbnail.exists?

        content_tag :div, class: "document-thumbnail" do
          presenter.thumbnail.thumbnail_tag({ alt: '' }, 'aria-hidden': true, tabindex: -1, counter: @counter)
        end
      end
    end

    # Content for the document metadata area
    def metadata
      @metadata || @view_context.render(@metadata_component.new(fields: presenter.field_presenters, show: show?))
    end

    # Content that goes before the document title (e.g. the counter)
    def before_title
      @before_title || counter
    end

    private

    def counter
      return unless @counter

      content_tag :span, class: 'document-counter' do
        t('blacklight.search.documents.counter', counter: @counter)
      end
    end

    def presenter
      @presenter ||= begin
        if show?
          @view_context.presenter(@document)
        else
          @view_context.index_presenter(@document)
        end
      end
    end

    def show?
      @show
    end
  end
end
