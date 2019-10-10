# frozen_string_literal: true

module Blacklight
  module Rendering
    # The field rendering pipeline.
    # This takes a field and its values and transforms them through a list of
    # operations.
    class Pipeline
      class_attribute :operations, instance_accessor: false

      # The ordered list of pipeline operations
      self.operations = [HelperMethod, LinkToFacet, Microdata, Join]

      # @param values [Array] the values for the field
      # @param config [Blacklight::Configuration::Field] the field's configuration
      # @param document [SolrDocument] the document
      # @param context [Object] an execution context, used to execute the helper method in.
      # @param operations [Array<Class>] the list of operations in this Pipeline
      # @param options [Hash] options to pass to the processors. Typically only `:value` is used
      def initialize(values, config, document, context, operations, options)
        @values = values
        @config = config
        @document = document
        @context = context
        @operations = operations
        @options = options
      end

      attr_reader :values, :config, :document, :context, :operations, :options

      # @param values [Array] the values for the field
      # @param config [Blacklight::Configuration::Field] the field's configuration
      # @param document [SolrDocument] the document
      # @param context [Object] an execution context, used to execute the  helper method in.
      # @param options [Hash] options to pass to the processors. Typically only `:value` is used
      def self.render(values, config, document, context, options)
        new(values, config, document, context, operations, options).render
      end

      # Perform the processing by the pipeline
      def render
        first, *rest = *stack
        first.new(values, config, document, context, options, rest).render
      end

      private

      # Ordered list of operations, Terminator must be at the end.
      def stack
        operations + [Terminator]
      end
    end
  end
end
