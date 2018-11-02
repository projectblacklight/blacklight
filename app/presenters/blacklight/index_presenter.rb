# frozen_string_literal: true
module Blacklight
  class IndexPresenter < DocumentPresenter
    class_attribute :thumbnail_presenter
    self.thumbnail_presenter = ThumbnailPresenter

    attr_reader :view_config

    # @param [SolrDocument] document
    # @param [ActionView::Base] view_context scope for linking and generating urls
    # @param [Blacklight::Configuration] configuration
    def initialize(document, view_context, configuration = view_context.blacklight_config)
      @document = document
      @view_context = view_context
      @configuration = configuration
      @view_config = configuration.view_config(view_context.document_index_view_type)
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
                  Deprecation.warn(self, "calling IndexPresenter.label with a Proc is deprecated. " \
                                         "First argument must be a symbol. This will be removed in Blacklight 8")
                  field_or_string_or_proc.call(document, opts)
                when String
                  Deprecation.warn(self, "calling IndexPresenter.label with a String is deprecated. " \
                                         "First argument must be a symbol. This will be removed in Blacklight 8")
                  field_or_string_or_proc
              end

      value ||= document.id
      field_values(config, value: value)
    end

    ##
    # Render the index field label for a document
    #
    # Allow an extention point where information in the document
    # may drive the value of the field
    # @param [Configuration::Field] field
    # @param [Hash] options
    # @option options [String] :value
    def field_value field, options = {}
      field_values(field, options)
    end

    def thumbnail
      @thumbnail ||= thumbnail_presenter.new(document, view_context, view_config)
    end

    private

    # @return [Hash<String,Configuration::Field>] all the fields for this index view
    def fields
      configuration.index_fields_for(document)
    end

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

    def field_config(field)
      configuration.index_fields.fetch(field) { Configuration::NullField.new(field) }
    end
  end
end
