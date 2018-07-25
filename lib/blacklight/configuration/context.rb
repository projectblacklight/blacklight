# frozen_string_literal: true

module Blacklight
  class Configuration
    # This class helps determine whether a specific field/tool should display for a
    # particular controller.  This is used when the field/tool is configured with an
    # _if_ or _unless_ argument.
    #
    # e.g.
    #   config.add_results_document_tool(:bookmark,
    #                                    partial: 'bookmark_control',
    #                                    if: :render_bookmarks_control?)
    #
    # The context points at the scope for where to evaluate the method _render_bookmarks_control?_
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
        return config if config == true || config == false

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
    end
  end
end
