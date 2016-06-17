# frozen_string_literal: true
module Blacklight
  class DocumentPresenter
    include ActionView::Helpers::OutputSafetyHelper
    include ActionView::Helpers::TagHelper
    extend Deprecation

    # @param [SolrDocument] document
    # @param [ActionController::Base] controller scope for linking and generating urls
    # @param [Blacklight::Configuration] configuration
    def initialize(document, controller, configuration = controller.blacklight_config)
      @document = document
      @configuration = configuration
      @controller = controller
    end

    ##
    # Get the value of the document's "title" field, or a placeholder
    # value (if empty)
    #
    # @param [SolrDocument] document
    # @return [String]
    def document_heading
      fields = Array(@configuration.view_config(:show).title_field)
      f = fields.find { |field| @document.has? field }

      value = f.nil? ? @document.id : @document[f]
      ValueRenderer.new(Array.wrap(value)).render
    end

    ##
    # Create <link rel="alternate"> links from a documents dynamically
    # provided export formats. Returns empty string if no links available.
    #
    # @params [SolrDocument] document
    # @params [Hash] options
    # @option options [Boolean] :unique ensures only one link is output for every
    #     content type, e.g. as required by atom
    # @option options [Array<String>] :exclude array of format shortnames to not include in the output
    def link_rel_alternates(options = {})
      options = { unique: false, exclude: [] }.merge(options)

      seen = Set.new

      safe_join(@document.export_formats.map do |format, spec|
        next if options[:exclude].include?(format) || (options[:unique] && seen.include?(spec[:content_type]))

        seen.add(spec[:content_type])

        tag(:link, rel: "alternate", title: format, type: spec[:content_type], href: @controller.polymorphic_url(@document, format: format))
      end.compact, "\n")
    end

    ##
    # Get the document's "title" to display in the <title> element.
    # (by default, use the #document_heading)
    #
    # @see #document_heading
    # @return [String]
    def document_show_html_title
      if @configuration.view_config(:show).html_title_field
        fields = Array(@configuration.view_config(:show).html_title_field)
        f = fields.find { |field| @document.has? field }
        f ||= 'id'
        field_config = @configuration.show_fields[f]
        get_field_values(f, field_config)
      else
        document_heading
      end
    end

    ##
    # Render the document index heading
    #
    # @param [Symbol, Proc, String] field Render the given field or evaluate the proc or render the given string
    # @param [Hash] opts
    def render_document_index_label(field, opts = {})
      label = case field
      when Symbol
        @document[field]
      when Proc
        field.call(@document, opts)
      when String
        field
      end

      label ||= @document.id
      ValueRenderer.new(Array.wrap(label)).render
    end

    ##
    # Render the index field label for a document
    #
    #   Allow an extention point where information in the document
    #   may drive the value of the field
    #   @param [String] field
    #   @param [Hash] opts
    #   @options opts [String] :value
    def render_index_field_value field, options = {}
      field_config = @configuration.index_fields[field]
      if options[:value]
        # TODO Fold this into get_field_values
        ValueRenderer.new(Array.wrap(options[:value]), field_config).render
      else
        get_field_values(field, field_config, options)
      end
    end

    ##
    # Render the show field value for a document
    #
    #   Allow an extention point where information in the document
    #   may drive the value of the field
    #   @param [String] field
    #   @param [Hash] options
    #   @options opts [String] :value
    def render_document_show_field_value field, options={}
      field_config = @configuration.show_fields[field]
      if options[:value]
        # TODO Fold this into get_field_values
        ValueRenderer.new(Array.wrap(options[:value]), field_config).render
      else
        get_field_values(field, field_config, options)
      end

    end

    ##
    # Get the value for a document's field, and prepare to render it.
    # - highlight_field
    # - accessor
    # - solr field
    #
    # Rendering:
    #   - helper_method
    #   - link_to_search
    # @param [SolrDocument] document
    # @param [String] field name
    # @param [Blacklight::Solr::Configuration::Field] solr field configuration
    # @param [Hash] options additional options to pass to the rendering helpers
    def get_field_values field, field_config, options = {}
      FieldPresenter.new(@controller, @document, field, field_config, options).render
    end

    # @deprecated
    def render_field_value(values, field_config = nil)
      Deprecation.warn(DocumentPresenter, "render_field_value is deprecated and will be removed in Blacklight 7. Use ValueRenderer instead")
      ValueRenderer.new(Array.wrap(values), field_config).render
    end

  end
end
