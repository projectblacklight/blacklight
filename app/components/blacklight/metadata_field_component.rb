# frozen_string_literal: true

module Blacklight
  class MetadataFieldComponent < ::ViewComponent::Base
    with_collection_parameter :field

    # @param field [Blacklight::FieldPresenter]
    # @param layout [Blacklight::MetadataFieldLayoutComponent] alternate layout component to use
    # @param show [Boolean] are we showing only a single document (vs a list of search results); used for backwards-compatibility
    def initialize(field:, layout: nil, show: false)
      @field = field
      @layout = layout || Blacklight::MetadataFieldLayoutComponent
      @show = show
    end

    # @private
    def label
      Deprecation.silence(Blacklight::BlacklightHelperBehavior) do
        if @show
          @view_context.render_document_show_field_label @field.document, label: @field.label('show'), field: @field.key
        else
          index_field_label @field.document, label: @field.label, field: @field.key
        end
      end
    end

    def render?
      @field.render_field?
    end

    ##
    # Render the index field label for a document
    #
    # Translations for index field labels should go under blacklight.search.fields
    # They are picked up from there by a value "%{label}" in blacklight.search.index.label
    #
    # @overload render_index_field_label(options)
    #   Use the default, document-agnostic configuration
    #   @param [Hash] opts
    #   @option opts [String] :field
    # @overload render_index_field_label(document, options)
    #   Allow an extention point where information in the document
    #   may drive the value of the field
    #   @param [SolrDocument] doc
    #   @param [Hash] opts
    #   @option opts [String] :field
    # @return [String]
    def index_field_label *args
      options = args.extract_options!
      document = args.first

      field = options[:field]
      label = Deprecation.silence(Blacklight::ConfigurationHelperBehavior) do
        options[:label] || index_field_label(document, field)
      end
      html_escape t(:"blacklight.search.index.#{helpers.document_index_view_type}.label", default: :'blacklight.search.index.label', label: label)
    end
  end
end
