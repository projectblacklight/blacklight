# frozen_string_literal: true

module Blacklight
  # Returned if no config is defined for a display field in the Blacklight::Configuration
  class Configuration::NullDisplayField < Blacklight::Configuration::DisplayField
    def initialize(field_or_hash = nil)
      case field_or_hash
      when String, Symbol
        super(field: field_or_hash)
      else
        super
      end

      normalize!
    end
  end
end
