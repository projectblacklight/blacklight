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
      return to_enum(:fields_to_render) unless block_given?

      fields.each do |name, field_config|
        field_presenter = field_presenter(field_config)

        next unless field_presenter.render_field? && field_presenter.any?

        yield name, field_config, field_presenter
      end
    end

    def field_presenters
      return to_enum(:field_presenters) unless block_given?

      fields_to_render.each { |_, _, config| yield config }
    end

    ##
    # Get the value of the document's "title" field, or a placeholder
    # value (if empty)
    #
    # @return [String]
    def heading
      return field_value(view_config.title_field) if view_config.title_field.is_a? Blacklight::Configuration::Field

      fields = Array.wrap(view_config.title_field) + [configuration.document_model.unique_key]
      f = fields.lazy.map { |field| field_config(field) }.detect { |field_config| field_presenter(field_config).any? }
      f ? field_value(f, except_operations: [Rendering::HelperMethod]) : ""
    end

    ##
    # Get the document's "title" to display in the <title> element.
    # (by default, use the #document_heading)
    #
    # @see #document_heading
    # @return [String]
    def html_title
      return field_value(view_config.html_title_field) if view_config.html_title_field.is_a? Blacklight::Configuration::Field

      if view_config.html_title_field
        fields = Array.wrap(view_config.html_title_field) + [configuration.document_model.unique_key]
        f = fields.lazy.map { |field| field_config(field) }.detect { |field_config| field_presenter(field_config).any? }
        field_value(f)
      else
        heading
      end
    end

    def display_type(base_name = nil, default: nil)
      fields = []
      fields += Array.wrap(view_config[:"#{base_name}_display_type_field"]) if base_name && view_config.key?(:"#{base_name}_display_type_field")
      fields += Array.wrap(view_config.display_type_field)

      if fields.empty? && show_view_config != view_config
        fields += Array.wrap(show_view_config[:"#{base_name}_display_type_field"]) if base_name && show_view_config.key?(:"#{base_name}_display_type_field")
        fields += Array.wrap(show_view_config.display_type_field)
      end

      fields += ['format'] if fields.empty? # backwards compatibility with the old default value for display_type_field

      display_type = fields.lazy.map { |field| field_presenter(field_config(field)) }.detect(&:any?)&.values
      display_type ||= Array(default) if default

      display_type || []
    end

    ##
    # Render the field label for a document
    #
    # Allow an extention point where information in the document
    # may drive the value of the field
    # @param [Configuration::Field] field_config
    # @param [Hash] options
    # @option options [String] :value
    def field_value field_config, options = {}
      field_presenter(field_config, options).render
    end

    def thumbnail_presenter_class
      view_config.thumbnail_presenter || thumbnail_presenter
    end

    def thumbnail
      @thumbnail ||= thumbnail_presenter_class.new(document, view_context, view_config)
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

    def view_config
      @view_config ||= show_view_config
    end

    def show_view_config
      configuration.view_config(:show)
    end

    private

    def field_presenter(field_config, options = {})
      presenter_class = field_config.presenter || Blacklight::FieldPresenter
      presenter_class.new(view_context, document, field_config, options.merge(field_presenter_options))
    end

    def field_presenter_options
      {}
    end
  end
end
