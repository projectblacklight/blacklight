# frozen_string_literal: true
module Blacklight
  class IndexPresenter
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
    # Render the document index heading
    #
    # @param [Symbol, Proc, String] field_or_string_or_proc Render the given field or evaluate the proc or render the given string
    # @param [Hash] opts
    # TODO: the default field should be `document_show_link_field(doc)'
    def label(field_or_string_or_proc, opts = {})
      config = Configuration::NullField.new
      value = case field_or_string_or_proc
      when Symbol
        config = field_config(field_or_string_or_proc)
        document[field_or_string_or_proc]
      when Proc
        field_or_string_or_proc.call(document, opts)
      when String
        field_or_string_or_proc
      end

      value ||= document.id
      field_values(config, value: value)
    end

    # @deprecated
    def render_document_index_label(*args)
      label(*args)
    end
    deprecation_deprecate render_document_index_label: 'Use #label instead'

    ##
    # Render the index field label for a document
    #
    # Allow an extention point where information in the document
    # may drive the value of the field
    # @param [String] field
    # @param [Hash] options
    # @option options [String] :value
    def field_value field, options = {}
      field_config = field_config(field)
      field_values(field_config, options)
    end

    # @deprecated
    def render_index_field_value(*args)
      field_value(*args)
    end
    deprecation_deprecate render_index_field_value: 'replaced by #field_value'

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

      def field_config(field)
        configuration.index_fields.fetch(field) { Configuration::NullField.new(field) }
      end
  end
end
