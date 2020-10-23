# frozen_string_literal: true

module Blacklight
  class DocumentComponent < ::ViewComponent::Base
    # Available content areas; some have defaults provided by
    # the accessors below.
    with_content_areas :header, :body, :footer,
                       :before_title, :title, :after_title,
                       :actions, :embed, :metadata, :thumbnail,
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
    # @param counter [Number, nil] a pre-computed counter for the position of this document in a search result set
    # @param document_counter [Number, nil] alternatively, the document's position in a collection and,
    # @param counter_offset [Number] with `document_counter`, the offset of the start of that collection counter to the overall result set
    # @param show [Boolean] are we showing only a single document (vs a list of search results); used for backwards-compatibility
    def initialize(document: nil, presenter: nil,
                   id: nil, classes: [], component: :article, title_component: :h4,
                   metadata_component: Blacklight::DocumentMetadataComponent,
                   embed_component: nil,
                   counter: nil, document_counter: nil, counter_offset: 0,
                   show: false)
      if presenter.nil? && document.nil?
        raise ArgumentError, 'missing keyword: :document or :presenter'
      end

      @document = document || presenter&.document
      @presenter = presenter

      @component = component
      @title_component = title_component
      @id = id || ('document' if show)
      @classes = classes

      @embed_component = embed_component
      @metadata_component = metadata_component

      @document_counter = document_counter
      @counter = counter
      @counter ||= document_counter + 1 + counter_offset if document_counter.present?

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
      return super if block_given?

      @title || if show?
                  content_tag('span', presenter.heading, itemprop: "name")
                else
                  @view_context.link_to_document @document, counter: @counter, itemprop: 'name'
                end
    end

    # Content for the document actions area
    def actions
      return super if block_given?

      return if @show

      @actions ||
        @view_context.render_index_doc_actions(@document, wrapping_class: "index-document-functions col-sm-3 col-lg-2")
    end

    # Content for the document thumbnail area
    def thumbnail
      return super if block_given?
      return if @show

      @thumbnail || render(Blacklight::Document::ThumbnailComponent.new(presenter: presenter, counter: @counter))
    end

    # Content for the document metadata area
    def metadata
      return super if block_given?

      @metadata || @view_context.render(@metadata_component.new(fields: presenter.field_presenters, show: show?))
    end

    # Content that goes before the document title (e.g. the counter)
    def before_title
      return super if block_given?

      @before_title || counter
    end

    def embed
      return @embed if @embed

      component = @embed_component || presenter.view_config.embed_component

      return unless component

      @view_context.render(component.new(document: @document, presenter: presenter, document_counter: @document_counter))
    end

    private

    def counter
      return unless @counter

      content_tag :span, class: 'document-counter' do
        t('blacklight.search.documents.counter', counter: @counter)
      end
    end

    def presenter
      @presenter ||= @view_context.document_presenter(@document)
    end

    def show?
      @show
    end
  end
end
