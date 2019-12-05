# frozen_string_literal: true

module Blacklight
  # An abstract class that the view presenters for SolrDocuments descend from
  class DocumentPresenter
    attr_reader :document, :configuration, :view_context

    class_attribute :thumbnail_presenter
    self.thumbnail_presenter = ThumbnailPresenter

    # @param [SolrDocument] document
    # @param [ActionView::Base] view_context scope for linking and generating urls
    # @param [Blacklight::Configuration] configuration
    def initialize(document, view_context, configuration = view_context.blacklight_config)
      @document = document
      @view_context = view_context
      @configuration = configuration
    end

    # @return [Hash<String,Configuration::Field>]  all the fields for this index view that should be rendered
    def fields_to_render
      fields.select do |_name, field_config|
        # rubocop:disable Style/PreferredHashMethods
        render_field?(field_config) && has_value?(field_config)
        # rubocop:enable Style/PreferredHashMethods
      end
    end

    ##
    # Get the value of the document's "title" field, or a placeholder
    # value (if empty)
    #
    # @return [String]
    def heading
      return field_values(view_config.title_field) if view_config.title_field.is_a? Blacklight::Configuration::Field

      fields = Array.wrap(view_config.title_field) + [configuration.document_model.unique_key]
      f = fields.lazy.map { |field| field_config(field) }.detect { |field_config| retrieve_values(field_config).any? }
      field_values(f, except_operations: [Rendering::HelperMethod])
    end

    def display_type(base_name = nil, default: nil)
      fields = []
      fields += Array.wrap(view_config[:"#{base_name}_display_type_field"]) if base_name && view_config.key?(:"#{base_name}_display_type_field")
      fields += Array.wrap(view_config.display_type_field)

      display_type = fields.lazy.map { |field| retrieve_values(field_config(field)) }.detect(&:any?)
      display_type ||= Array(default) if default

      display_type || []
    end

    ##
    # Render the field label for a document
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

    ##
    # Check to see if the given field should be rendered in this context
    # @param [Blacklight::Configuration::Field] field_config
    # @return [Boolean]
    def render_field?(field_config)
      view_context.should_render_field?(field_config, document)
    end

    ##
    # Check if a document has (or, might have, in the case of accessor methods) a value for
    # the given solr field
    # @param [Blacklight::Configuration::Field] field_config
    # @return [Boolean]
    def has_value?(field_config)
      retrieve_values(field_config).present?
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
      options[:values] ||= retrieve_values(field_config) unless options.key? :value
      FieldPresenter.new(view_context, document, field_config, options).render
    end

    def retrieve_values(field_config)
      FieldRetriever.new(document, field_config).fetch
    end
  end
end
