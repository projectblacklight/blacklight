# frozen_string_literal: true

module Blacklight
  # Renders a field and handles link_to_facet or helper_method if supplied
  class FieldPresenter
    # @param controller [Object] the context in which to execute helper methods
    # @param document [SolrDocument] the document
    # @param field_config [Blacklight::Configuration::Field] the field's configuration
    # @param options [Hash]
    # @option options [Object] :value when this is provided, we don't want the pipeline to deal with helper methods.
    #                                 this happens when drawing the label for the document
    def initialize(controller, document, field_config, options)
      @controller = controller
      @document = document
      @field_config = field_config
      @options = options
    end

    attr_reader :controller, :document, :field_config, :options

    def render
      return Rendering::Pipeline.render(retrieve_values, field_config, document, controller, options) unless options[:value]

      values = Array.wrap(options[:value])
      # Prevents helper methods from drawing.
      steps = Rendering::Pipeline.operations - [Rendering::HelperMethod]
      Rendering::Pipeline.new(values, field_config, document, controller, steps, options).render
    end

    private

    def retrieve_values
      FieldRetriever.new(document, field_config).fetch
    end
  end
end
