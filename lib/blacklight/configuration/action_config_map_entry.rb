# frozen_string_literal: true

module Blacklight
  class Configuration::ActionConfigMapEntry < OpenStructWithHashAccess
    # @!attribute parent_action_key
    # Pull in the configuration for this action from another action's config
    # @return [Symbol]

    def parent_config = parent_action_key

    def parent_config=(value)
      self.parent_action_key = value
    end

    #
    # @!attribute blacklight_config_property
    # Pull in the configuration for this action from a top-level config
    # @return [Symbol]

    def top_level_config = blacklight_config_property

    def top_level_config=(value)
      self.blacklight_config_property = value
    end

    #
    # @!attribute default
    # Pull in additional default configuration for this action from a top-level config
    # @return [Array<Symbol>]
  end
end
