# frozen_string_literal: true
module Blacklight
  class ShowPresenter
    attr_reader :document, :configuration, :view_context

    # @param [SolrDocument] document
    # @param [ActionView::Base] view_context scope for linking and generating urls
    # @param [Blacklight::Configuration] configuration
    def initialize(document, view_context, configuration = view_context.blacklight_config)
      @document = document
      @view_context = view_context
      @configuration = configuration
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
        field_values(field_config(f))
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
      field_values(field_config(f), value: document[f])
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
      configuration.show_fields.values.each do |field|
        yield(field) if render_field?(field)
      end
    end

    ##
    # Render the show field value for a document
    #
    # Allow an extention point where information in the document
    # may drive the value of the field
    # @param [Blacklight::Configuration::Field] field
    # @param [Hash] options
    # @option options [String] :value
    def field_value field, options = {}
      field_values(field, options)
    end

    ##
    # Render the show field label for a document
    #
    # @param [Blacklight::Configuration::Field] field
    def field_label field
      I18n.t(:'blacklight.search.show.label',
             label: field.show_field_label)
    end

    private

    ##
    # Get the value for a document's field, and prepare to render it.
    # - highlight_field
    # - accessor
    # - solr field
    #
    # Rendering:
    #   - helper_method
    #   - link_to_facet
    # @param [Blacklight::Configuration::Field] field_config solr field configuration
    # @param [Hash] options additional options to pass to the rendering helpers
    def field_values(field_config, options = {})
      FieldPresenter.new(view_context, document, field_config, options).render
    end

    def view_config
      configuration.view_config(:show)
    end

    def field_config(field)
      configuration.show_fields.fetch(field) { Configuration::NullField.new(field) }
    end
  end
end
