# frozen_string_literal: true
module Blacklight::RenderPartialsHelperBehavior
  ##
  # Render the document index view
  #
  # @param [Array<SolrDocument>] documents list of documents to render
  # @param [Hash] locals to pass to the render call
  # @return [String]
  def render_document_index documents = nil, locals = {}
    documents ||= @response.documents
    render_document_index_with_view(document_index_view_type, documents, locals)
  end

  ##
  # Render the document index for a grouped response
  def render_grouped_document_index
    render 'catalog/group'
  end

  ##
  # Return the list of partials for a given solr document
  # @param [SolrDocument] doc solr document to render partials for
  # @param [Array<String>] partials list of partials to render
  # @param [Hash] locals local variables to pass to the render call
  # @return [String]
  def render_document_partials(doc, partials = [], locals = {})
    safe_join(partials.map do |action_name|
      render_document_partial(doc, action_name, locals)
    end, "\n")
  end

  ##
  # Given a doc and a base name for a partial, this method will attempt to render
  # an appropriate partial based on the document format and view type.
  #
  # If a partial that matches the document format is not found,
  # render a default partial for the base name.
  #
  # @see #document_partial_path_templates
  #
  # @param [SolrDocument] doc
  # @param [String] base_name base name for the partial
  # @param [Hash] locals local variables to pass through to the partials
  def render_document_partial(doc, base_name, locals = {})
    format = document_partial_name(doc, base_name)

    view_type = document_index_view_type
    template = cached_view ['show', view_type, base_name, format].join('_') do
      find_document_show_template_with_view(view_type, base_name, format, locals)
    end
    if template
      template.render(self, locals.merge(document: doc))
    else
      ''
    end
  end

  ##
  # Render the document index for the given view type with the
  # list of documents.
  #
  # This method will interpolate the list of templates with
  # the current view, and gracefully handles missing templates.
  #
  # @see #document_index_path_templates
  #
  # @param [String] view type
  # @param [Array<SolrDocument>] documents list of documents to render
  # @param [Hash] locals to pass to the render call
  # @return [String]
  def render_document_index_with_view view, documents, locals = {}
    template = cached_view ['index', view].join('_') do
      find_document_index_template_with_view(view, locals)
    end

    if template
      template.render(self, locals.merge(documents: documents))
    else
      ''
    end
  end

  ##
  # A list of document partial templates to attempt to render
  #
  # @see #render_document_index_with_view
  # @return [Array<String>]
  def document_index_path_templates
    # first, the legacy template names for backwards compatbility
    # followed by the new, inheritable style
    # finally, a controller-specific path for non-catalog subclasses
    @document_index_path_templates ||= [
      "document_%{index_view_type}",
      "catalog/document_%{index_view_type}",
      "catalog/document_list"
    ]
  end

  protected

    ##
    # Return a partial name for rendering a document
    # this method can be overridden in order to transform the value
    #   (e.g. 'PdfBook' => 'pdf_book')
    #
    # @param [SolrDocument] document
    # @param [String, Array] display_type a value suggestive of a partial
    # @return [String] the name of the partial to render
    # @example
    #  type_field_to_partial_name(['a book-article'])
    #  => 'a_book_article'
    if Rails.version >= '5.0.0'
      def type_field_to_partial_name(_document, display_type)
        # using "_" as sep. to more closely follow the views file naming conventions
        # parameterize uses "-" as the default sep. which throws errors
        underscore = '_'.freeze
        Array(display_type).join(' '.freeze).tr('-'.freeze, underscore).parameterize(separator: underscore)
      end
    else
      def type_field_to_partial_name(_document, display_type)
        # using "_" as sep. to more closely follow the views file naming conventions
        # parameterize uses "-" as the default sep. which throws errors
        underscore = '_'.freeze
        Array(display_type).join(' '.freeze).tr('-'.freeze, underscore).parameterize(underscore)
      end
    end

    ##
    # Return a normalized partial name for rendering a single document
    #
    # @param [SolrDocument] document
    # @param [Symbol] base_name base name for the partial
    # @return [String]
    def document_partial_name(document, base_name = nil)
      view_config = blacklight_config.view_config(:show)

      display_type = if base_name && view_config.key?(:"#{base_name}_display_type_field")
                       document[view_config[:"#{base_name}_display_type_field"]]
                     end

      display_type ||= document[view_config.display_type_field]

      display_type ||= 'default'

      type_field_to_partial_name(document, display_type)
    end

    ##
    # A list of document partial templates to try to render for a document
    #
    # The partial names will be interpolated with the following variables:
    #   - action_name: (e.g. index, show)
    #   - index_view_type: (the current view type, e.g. list, gallery)
    #   - format: the document's format (e.g. book)
    #
    # @see #render_document_partial
    def document_partial_path_templates
      # first, the legacy template names for backwards compatbility
      # followed by the new, inheritable style
      # finally, a controller-specific path for non-catalog subclasses
      @partial_path_templates ||= [
        "%{action_name}_%{index_view_type}_%{format}",
        "%{action_name}_%{index_view_type}_default",
        "%{action_name}_%{format}",
        "%{action_name}_default",
        "%{action_name}",
        "catalog/%{action_name}_%{format}",
        "catalog/_%{action_name}_partials/%{format}",
        "catalog/_%{action_name}_partials/default"
      ]
    end

  private

    def find_document_show_template_with_view view_type, base_name, format, locals
      document_partial_path_templates.each do |str|
        partial = str % { action_name: base_name, format: format, index_view_type: view_type }
        logger.debug "Looking for document partial #{partial}"
        template = lookup_context.find_all(partial, lookup_context.prefixes + [""], true, locals.keys + [:document], {}).first
        return template if template
      end
      nil
    end

    def find_document_index_template_with_view view, locals
      document_index_path_templates.each do |str|
        partial = str % { index_view_type: view }
        logger.debug "Looking for document index partial #{partial}"
        template = lookup_context.find_all(partial, lookup_context.prefixes + [""], true, locals.keys + [:documents], {}).first
        return template if template
      end
      nil
    end

    ##
    # @param key fetches or writes data to a cache, using the given key.
    # @yield the block to evaluate (and cache) if there is a cache miss
    def cached_view key
      @view_cache ||= {}
      if @view_cache.key?(key)
        @view_cache[key]
      else
        @view_cache[key] = yield
      end
    end
end
