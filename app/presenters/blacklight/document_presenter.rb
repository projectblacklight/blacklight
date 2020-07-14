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
    # @param [Integer] counter what offset in the search result is this record (used for tracking)
    def initialize(document, view_context, configuration = view_context.blacklight_config, counter: nil)
      @document = document
      @view_context = view_context
      @configuration = configuration
      @counter = counter
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

    ##
    # Get the value of the document's "title" field, or a placeholder
    # value (if empty)
    #
    # @return [String]
    def heading
      return field_value(view_config.title_field) if view_config.title_field.is_a? Blacklight::Configuration::Field

      fields = Array.wrap(view_config.title_field) + [configuration.document_model.unique_key]
      f = fields.lazy.map { |field| field_config(field) }.detect { |field_config| field_presenter(field_config).any? }
      field_value(f, except_operations: [Rendering::HelperMethod])
    end

    def display_type(base_name = nil, default: nil)
      fields = []
      fields += Array.wrap(view_config[:"#{base_name}_display_type_field"]) if base_name && view_config.key?(:"#{base_name}_display_type_field")
      fields += Array.wrap(view_config.display_type_field)

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

    def thumbnail
      @thumbnail ||= thumbnail_presenter.new(document, view_context, view_config, counter: @counter)
    end

    private

    def render_field?(field_config)
      field_presenter(field_config).render_field?
    end
    deprecation_deprecate render_field?: 'Use FieldPresenter#render_field?'

    def has_value?(field_config)
      field_presenter(field_config).any?
    end
    deprecation_deprecate has_value?: 'Use FieldPresenter#any?'

    def field_values(field_config, options = {})
      field_value(field_config, options)
    end
    deprecation_deprecate field_values: 'Use #field_value'

    def retrieve_values(field_config)
      field_presenter(field_config).values
    end
    deprecation_deprecate retrieve_values: 'Use FieldPresenter#values'

    def field_presenter(field_config, options = {})
      presenter_class = field_config.presenter || Blacklight::FieldPresenter
      presenter_class.new(view_context, document, field_config, options)
    end
  end
end
