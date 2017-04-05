module Blacklight
  module Rendering
    # The field rendering pipeline
    class Pipeline
      class_attribute :operations

      # The ordered list of pipeline operations
      self.operations = [HelperMethod, LinkToFacet, Microdata, Join]

      def initialize(values, config, document, context, options)
        @values = values
        @config = config
        @document = document
        @context = context
        @options = options
      end

      attr_reader :values, :config, :document, :context, :options

      def self.render(values, config, document, context, options)
        new(values, config, document, context, options).render
      end

      def render
        first, *rest = *stack
        first.new(values, config, document, context, options, rest).render
      end

      protected

      # Ordered list of operations, Terminator must be at the end.
      def stack
        operations + [Terminator]
      end
    end
  end
end
