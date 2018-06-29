# frozen_string_literal: true

module Blacklight
  # Returned if no config is defined for the field in the Blacklight::Configuration
  class Configuration::NullField < Blacklight::Configuration::Field
    def initialize(field_or_hash = nil)
      case field_or_hash
      when String, Symbol
        super(field: field_or_hash)
      else
        super
      end
    end
  end
end
