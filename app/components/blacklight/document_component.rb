# frozen_string_literal: true

module Blacklight
  class DocumentComponent < Blacklight::Component
    # Content appearing before the document
    renders_one :header

    # Content appearing after the document
    renders_one :footer

    # Content appearing instead of the regularly rendered document; its use is discouraged, but is a stop-gap until
    # the ecosystem fully adopts view components.
    renders_one :body

    # The document title with some reasonable default behavior
    renders_one :title, (lambda do |*args, component: nil, **kwargs|
      component ||= Blacklight::DocumentTitleComponent

      component.new(*args, counter: @counter, document: @document, presenter: @presenter, as: @title_component, actions: !@show, link_to_document: !@show, document_component: self, **kwargs)
    end)

    renders_one :embed, (lambda do |static_content = nil, *args, component: nil, **kwargs|
      next static_content if static_content.present?

      component ||= @presenter.view_config&.embed_component

      next unless component

      component.new(*args, document: @document, presenter: @presenter, document_counter: @document_counter, **kwargs)
    end)

    # The primary metadata section
    renders_one :metadata, (lambda do |static_content = nil, *args, component: nil, fields: nil, **kwargs|
      next static_content if static_content.present?

      component ||= Blacklight::DocumentMetadataComponent

      component.new(*args, fields: fields || @presenter&.field_presenters || [], **kwargs)
    end)

    # Additional metadata sections
    renders_many :metadata_sections

    renders_one :thumbnail, (lambda do |image_options_or_static_content = {}, *args, component: nil, **kwargs|
      next image_options_or_static_content if image_options_or_static_content.is_a? String

      component ||= @presenter&.view_config&.thumbnail_component || Blacklight::Document::ThumbnailComponent

      component.new(*args, document: @document, presenter: @presenter, counter: @counter, image_options: image_options_or_static_content, **kwargs)
    end)

    # A container for partials rendered using the view config partials configuration. Its use is discouraged, but necessary until
    # the ecosystem fully adopts view components.
    renders_many :partials

    # Backwards compatibility
    renders_one :actions

    # rubocop:disable Metrics/ParameterLists
    # @param document [Blacklight::Document]
    # @param presenter [Blacklight::DocumentPresenter]
    # @param id [String] HTML id for the root element
    # @param classes [Array, String] additional HTML classes for the root element
    # @param component [Symbol, String] HTML tag type to use for the root element
    # @param title_component [Symbol, String] HTML tag type to use for the title element
    # @param counter [Number, nil] a pre-computed counter for the position of this document in a search result set
    # @param document_counter [Number, nil] alternatively, the document's position in a collection and,
    # @param counter_offset [Number] with `document_counter`, the offset of the start of that collection counter to the overall result set
    # @param show [Boolean] are we showing only a single document (vs a list of search results); used for backwards-compatibility
    def initialize(document: nil, presenter: nil,
                   id: nil, classes: [], component: :article, title_component: nil,
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
        helpers.render_document_class(@document),
        'document',
        ("document-position-#{@counter}" if @counter)
      ].compact.flatten
    end

    def before_render
      set_slot(:title, nil) unless title
      set_slot(:thumbnail, nil) unless thumbnail || show?
      set_slot(:metadata, nil, fields: presenter.field_presenters) unless metadata
      set_slot(:embed, nil) unless embed
    end

    private

    def presenter
      @presenter ||= helpers.document_presenter(@document)
    end

    def show?
      @show
    end
  end
end
