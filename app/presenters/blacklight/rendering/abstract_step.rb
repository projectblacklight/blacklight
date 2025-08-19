# frozen_string_literal: true

module Blacklight
  module Rendering
    class AbstractStep
      def initialize(values, config, document, context, options, stack)
        @values = values
        @config = config
        @document = document
        @context = context
        @options = options
        @stack = stack
      end

      attr_reader :values, :config, :document, :context, :options, :stack

      private

      def next_step(output_values)
        first, *rest = *stack
        first.new(output_values, config, document, context, options, rest).render
      end

      def html?
        format.nil? || format.to_s == 'html'
      end

      def format
        return options[:format] unless context.respond_to?(:search_state)

        options[:format] || context.search_state&.params&.dig(:format)
      end
    end
  end
end
