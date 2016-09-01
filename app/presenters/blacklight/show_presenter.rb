# frozen_string_literal: true
module Blacklight
  class ShowPresenter
    extend Deprecation
    self.deprecation_horizon = 'Blacklight version 7.0.0'

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
    # @deprecated moved to ShowPresenter#link_rel_alternates
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

    # @deprecated
    def document_show_html_title
      html_title
    end
    deprecation_deprecate document_show_html_title: "use #html_title"

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

    # @deprecated
    def document_heading
      heading
    end
    deprecation_deprecate document_heading: "replaced by #heading"

    ##
    # Render the show field value for a document
    #
    # Allow an extention point where information in the document
    # may drive the value of the field
    # @param [String] field
    # @param [Hash] options
    # @option options [String] :value
    def field_value field, options={}
      field_values(field_config(field), options)
    end

    # @deprecated
    def render_document_show_field_value(*args)
      field_value(*args)
    end
    deprecation_deprecate render_document_show_field_value: 'replaced by #field_value'

    # @deprecated
    def get_field_values(field_config, options={})
      field_values(field_config, options)
    end
    deprecation_deprecate get_field_values: "replaced by #field_value"

    # @deprecated
    def render_field_values(values, field_config = Configuration::NullField.new)
      field_values(field_config, value: Array(values))
    end
    deprecation_deprecate render_field_values: "replaced by #field_value"

    # @deprecated
    def render_values(values, field_config = Configuration::NullField.new)
      field_values(field_config, value: Array(values))
    end
    deprecation_deprecate render_values: "replaced by #field_value"

    private

      ##
      # Get the value for a document's field, and prepare to render it.
      # - highlight_field
      # - accessor
      # - solr field
      #
      # Rendering:
      #   - helper_method
      #   - link_to_search
      # @param [Blacklight::Configuration::Field] field_config solr field configuration
      # @param [Hash] options additional options to pass to the rendering helpers
      def field_values(field_config, options={})
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
