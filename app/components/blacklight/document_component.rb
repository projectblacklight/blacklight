# frozen_string_literal: true

require 'view_component/version'

module Blacklight
  ##
  # A component for rendering a single document
  #
  # @note when subclassing this component, if you override the initializer,
  #    you must explicitly specify the counter variable `document_counter` even if you don't use it.
  #    Otherwise view_component will not provide the count value when calling the component.
  #
  # @see https://viewcomponent.org/guide/collections.html#collection-counter
  #
  # @example
  #  class MyDocumentComponent < Blacklight::DocumentComponent
  #    def initialize(document_counter: nil, **kwargs)
  #      super
  #      ... custom code ...
  #    end
  #  end
  class DocumentComponent < Blacklight::Component
    with_collection_parameter :document

    # ViewComponent 3 changes iteration counters to begin at 0 rather than 1
    COLLECTION_INDEX_OFFSET = ViewComponent::VERSION::MAJOR < 3 ? 0 : 1

    # Content appearing before the document
    renders_one :header

    # Content appearing after the document
    renders_one :footer

    # Content appearing instead of the regularly rendered document; its use is discouraged, but is a stop-gap until
    # the ecosystem fully adopts view components.
    renders_one :body

    # The document title with some reasonable default behavior
    renders_one :title, (lambda do |*args, component: nil, **kwargs|
      component ||= @presenter&.view_config&.title_component || Blacklight::DocumentTitleComponent

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

      component ||= @presenter&.view_config&.metadata_component || Blacklight::DocumentMetadataComponent

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
    # @param document [Blacklight::DocumentPresenter]
    # @param presenter [Blacklight::DocumentPresenter] alias for document
    # @param partials [Array, nil] view partial names that should be used to provide content for the `partials` slot
    # @param id [String] HTML id for the root element
    # @param classes [Array, String] additional HTML classes for the root element
    # @param component [Symbol, String] HTML tag type to use for the root element
    # @param title_component [Symbol, String] HTML tag type to use for the title element
    # @param counter [Number, nil] a pre-computed counter for the position of this document in a search result set
    # @param document_counter [Number, nil] provided by ViewComponent collection iteration
    # @param counter_offset [Number] the offset of the start of the collection counter parameter for the component to the overall result set
    # @param show [Boolean] are we showing only a single document (vs a list of search results); used for backwards-compatibility
    def initialize(document: nil, presenter: nil, partials: nil,
                   id: nil, classes: [], component: :article, title_component: nil,
                   counter: nil, document_counter: nil, counter_offset: 0,
                   show: false, **args)
      Blacklight.deprecation.warn('the `presenter` argument to DocumentComponent#initialize is deprecated; pass the `presenter` in as document instead') if presenter

      @presenter = presenter || document || args[self.class.collection_parameter]
      @document = @presenter.document
      @view_partials = partials || []

      @component = component
      @title_component = title_component
      @id = id || ('document' if show)
      @classes = classes

      @counter = counter
      @document_counter = document_counter || args.fetch(self.class.collection_counter_parameter, nil)
      @counter ||= @document_counter + COLLECTION_INDEX_OFFSET + counter_offset if @document_counter.present?

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
      set_slot(:metadata, nil, fields: presenter.field_presenters, show: @show) unless metadata
      set_slot(:embed, nil) unless embed
      if view_partials.present?
        view_partials.each do |view_partial|
          with_partial(view_partial) do
            helpers.render_document_partial @document, view_partial, component: self, document_counter: @counter
          end
        end
      else
        set_slot(:partials, nil)
      end
    end

    private

    attr_reader :document_counter, :presenter, :view_partials

    def show?
      @show
    end
  end
end
