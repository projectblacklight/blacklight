# frozen_string_literal: true

module Blacklight
  # @abstract
  class DocumentPartialsRenderer
    # @param [#document] presenter for the object
    # @param [Array<String>] partials list of partials to render
    # @param [#lookup_context,#safe_join,#logger] view the rails view context
    def initialize(presenter:, partials:, view:)
      @presenter = presenter
      @partials = partials
      @view = view
    end

    ##
    # Return the list of partials for a given solr document
    # @param [Hash] locals local variables to pass to the render call
    # @return [String]
    def render(locals = {})
      safe_join(@partials.map do |action_name|
        render_partial(action_name, locals)
      end, "\n")
    end

    private

    delegate :logger, :lookup_context, :safe_join, to: :@view

    ##
    # Given a doc and a base name for a partial, this method will attempt to render
    # an appropriate partial based on the document format and view type.
    #
    # If a partial that matches the document format is not found,
    # render a default partial for the base name.
    #
    # @see #path_templates
    #
    # @param [String] base_name base name for the partial
    # @param [Hash] locals local variables to pass through to the partials
    def render_partial(base_name, locals = {})
      format = format_name(base_name)

      template = find_template(base_name, format, locals)
      if template
        template.render(@view, locals.merge(document: @presenter.document))
      else
        ''
      end
    end

    ##
    # Return a normalized format name for rendering a single document
    #
    # @param [SolrDocument] document
    # @param [Symbol] base_name base name for the partial
    # @return [String]
    # @example format_name(:show) => 'pdf_book'
    def format_name(base_name)
      display_type = @presenter.display_type(base_name, default: 'default')

      type_field_to_partial_name(display_type)
    end

    def find_template base_name, format, locals
      path_templates.each do |str|
        partial = partial_name(str, base_name, format)
        logger.debug "[#{self.class}] Looking for document partial #{partial}"
        template = lookup_context.find_all(partial, lookup_context.prefixes + [""], true, locals.keys + [:document], {}).first
        return template if template
      end
      nil
    end

    # Used in #find_template
    def partial_name(str, base_name, format)
      format(str, action_name: base_name, format: format)
    end

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
    def type_field_to_partial_name(display_type)
      # using "_" as sep. to more closely follow the views file naming conventions
      # parameterize uses "-" as the default sep. which throws errors
      Array(display_type).join(' ').tr('-', '_').parameterize(separator: '_')
    end
  end
end
