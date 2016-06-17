module Blacklight
  module Rendering
    # The field rendering pipeline
    class Pipeline
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
          [HelperMethod, LinkToFacet, Microdata, Join, Terminator]
        end
    end
  end
end
