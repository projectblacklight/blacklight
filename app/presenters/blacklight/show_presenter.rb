# frozen_string_literal: true
module Blacklight
  class ShowPresenter
    attr_reader :document, :configuration, :view_context, :search_context

    # @param [SolrDocument] document
    # @param [ActionView::Base] view_context scope for linking and generating urls
    # @param [Blacklight::Configuration] configuration
    # @param [Hash] search_context contains the next and previous documents in the current search
    def initialize(document, view_context, configuration = view_context.blacklight_config, search_context = {})
      @document = document
      @view_context = view_context
      @configuration = configuration
      @search_context = search_context
    end

    ##
    # Create <link rel="alternate"> links from a documents dynamically
    # provided export formats. Returns empty string if no links available.
    #
    # @param [Hash] options
    # @option options [Boolean] :unique ensures only one link is output for every
    #     content type, e.g. as required by atom
    # @option options [Array<String>] :exclude array of format shortnames to not include in the output
    def link_rel_alternates(options = {})
      LinkAlternatePresenter.new(view_context, document, options).render
    end

    ##
    # Render the main content partial for a document
    #
    # @return [String]
    def render_content_partial
      view_context.render 'show_main_content', presenter: self
    end

    ##
    # Render the document "heading" (title) in a content tag
    #   @param [Hash] options
    #   @option options [Symbol] :tag
    def render_document_heading(options = {})
      tag = options.fetch(:tag, :h4)
      view_context.content_tag(tag, heading, itemprop: "name")
    end

    ##
    # Get the document's "title" to display in the <title> element.
    # (by default, use the #document_heading)
    #
    # @see #document_heading
    # @return [String]
    def html_title
      if view_config.html_title_field
        fields = Array.wrap(view_config.html_title_field)
        f = fields.detect { |field| document.has? field }
        f ||= 'id'
        build_field_presenter(field_config(f)).value
      else
        heading
      end
    end

    ##
    # Get the value of the document's "title" field, or a placeholder
    # value (if empty)
    #
    # @return [String]
    def heading
      fields = Array.wrap(view_config.title_field)
      f = fields.detect { |field| document.has? field }
      f ||= configuration.document_model.unique_key
      build_field_presenter(field_config(f)).value(value: document[f])
    end

    ##
    # Determine whether to render a given field in the show view
    #
    # @param [Blacklight::Configuration::Field] field_config
    # @return [Boolean]
    def render_field? field_config
      view_context.should_render_field?(field_config, document) &&
        view_context.document_has_value?(document, field_config)
    end

    # @yields [Configuration::Field] each of the fields that should be rendered
    def fields
      configuration.show_fields.each_value do |field|
        yield(build_field_presenter(field)) if render_field?(field)
      end
    end

    # @param [Configuration::IndexField]
    # @return [IndexFieldPresenter]
    def build_field_presenter(field)
      ShowFieldPresenter.new(self, field)
    end

    private

    def view_config
      configuration.view_config(:show)
    end

    def field_config(field)
      configuration.show_fields.fetch(field) { Configuration::NullField.new(field) }
    end
  end
end
