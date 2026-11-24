# frozen_string_literal: true

module Blacklight
  # Supports the deprecated behavior of helpers falling back to controller-assigned
  # instance variables (e.g. @response or @document) when an argument isn't passed.
  # This module will be removed in Blacklight 10.
  # @private
  module DeprecatedInstanceVariableHelperBehavior
    private

    # Read an instance variable as a deprecated fallback for a missing argument,
    # warning if the instance variable provided a value.
    #
    # @param [Symbol] ivar_name the instance variable to read (e.g. :@response)
    # @param [String] method_name the helper method that relied on the fallback
    # @param [String] argument the name of the argument callers should pass instead
    def deprecated_instance_variable_fallback(ivar_name, method_name:, argument:)
      value = instance_variable_get(ivar_name)

      unless value.nil?
        Blacklight.deprecation.warn("Calling ##{method_name} without passing `#{argument}` is deprecated; " \
                                    "the fallback to #{ivar_name} will be removed in Blacklight 10.")
      end

      value
    end
  end
end
