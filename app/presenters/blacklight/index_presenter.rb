# frozen_string_literal: true
module Blacklight
  class IndexPresenter
    # @param [SolrDocument] document
    # @param [ActionController::Base] controller scope for linking and generating urls
    # @param [Blacklight::Configuration] configuration
    def initialize(document, controller, configuration = controller.blacklight_config)
      @document = document
      @configuration = configuration
      @controller = controller
    end

    ##
    # Render the document index heading
    #
    # @param [Symbol, Proc, String] field Render the given field or evaluate the proc or render the given string
    # @param [Hash] opts
    # TODO: the default field should be `document_show_link_field(doc)'
    def label(field, opts = {})
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
    # Allow an extention point where information in the document
    # may drive the value of the field
    # @param [String] field
    # @param [Hash] opts
    # @options opts [String] :value
    def field_value field, options = {}
      field_config = field_config(field)
      if options[:value]
        # TODO: Fold this into field_values
        ValueRenderer.new(Array.wrap(options[:value]), field_config).render
      else
        field_values(field_config, options)
      end
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
      #   - link_to_search
      # @param [Blacklight::Configuration::Field] solr field configuration
      # @param [Hash] options additional options to pass to the rendering helpers
      def field_values(field_config, options={})
        FieldPresenter.new(@controller, @document, field_config, options).render
      end

      def field_config(field)
        @configuration.index_fields.fetch(field) { Configuration::NullField.new(field) }
      end
  end
end

