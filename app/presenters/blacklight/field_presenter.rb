# frozen_string_literal: true

module Blacklight
  # Renders a field and handles link_to_facet or helper_method if supplied
  class FieldPresenter
    # @param view_context [Object] the context in which to execute helper methods
    # @param document [SolrDocument] the document
    # @param field_config [Blacklight::Configuration::Field] the field's configuration
    # @param options [Hash]
    # @option options [Object] :values
    # @option options [Array] :except_operations
    # @option options [Object] :value
    # @option options [Array] :steps
    def initialize(view_context, document, field_config, options = {})
      @view_context = view_context
      @document = document
      @field_config = field_config
      @options = options

      @values = if options.key?(:value)
                  Array.wrap(options[:value])
                else
                  options[:values]
                end

      @except_operations = options[:except_operations] || []
      @except_operations += field_config.except_operations || []
      # Implicitly prevent helper methods from drawing when drawing the label for the document
      @except_operations += [Rendering::HelperMethod] if options.key? :value
    end

    attr_reader :view_context, :document, :field_config, :except_operations, :options
    delegate :key, to: :field_config

    # @return [String]
    def render
      Rendering::Pipeline.new(values, field_config, document, view_context, pipeline_steps, options).render
    end

    # @return [Enumerable]
    def values
      @values ||= retrieve_values
    end

    # @param [String] context
    # @return [String]
    def label(context = nil, **options)
      field_config.display_label(context || options.fetch(:context, 'index'), count: retrieve_values.count, **options)
    end

    ##
    # Check to see if the given field should be rendered in this context
    # @return [Boolean]
    def render_field?
      view_context.should_render_field?(field_config, document)
    end

    ##
    # Check if a document has (or, might have, in the case of accessor methods) a value for
    # the given solr field
    # @return [Boolean]
    def any?
      values.present?
    end

    private

    def pipeline_steps
      (options[:steps] || field_config[:steps] || Rendering::Pipeline.operations) - except_operations
    end

    def retrieve_values
      FieldRetriever.new(document, field_config, view_context).fetch
    end
  end
end
