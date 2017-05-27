# frozen_string_literal: true
module Blacklight
  class Configuration
    class Context
      attr_reader :context

      def initialize(context)
        @context = context
      end

      ##
      # Evaluate conditionals for a configuration with if/unless attributes
      #
      # @param [#if,#unless] config an object that responds to if/unless
      # @return [Boolean]
      def evaluate_if_unless_configuration(config, *args)
        return config if config == true or config == false

        if_value = !config.respond_to?(:if) ||
                        config.if.nil? ||
                        evaluate_configuration_conditional(config.if, config, *args)

        unless_value = !config.respond_to?(:unless) ||
                          config.unless.nil? ||
                          !evaluate_configuration_conditional(config.unless, config, *args)

        if_value && unless_value
      end

      def evaluate_configuration_conditional(proc_helper_or_boolean, *args_for_procs_and_methods)
        case proc_helper_or_boolean
        when Symbol
          arity = context.method(proc_helper_or_boolean).arity

          if arity.zero?
            context.send(proc_helper_or_boolean)
          else
            context.send(proc_helper_or_boolean, *args_for_procs_and_methods)
          end
        when Proc
          proc_helper_or_boolean.call context, *args_for_procs_and_methods
        else
          proc_helper_or_boolean
        end
      end

      def evaluate_sorting_configuration(config, *args)
        if config.respond_to?(:sort_field_by)
          context.send(config.sort_field_by, config)
        else
          nil
        end
      end
    end
  end
end
