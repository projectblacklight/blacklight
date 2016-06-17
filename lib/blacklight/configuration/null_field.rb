module Blacklight
  # Returned if no config is defined for the field in the Blacklight::Configuration
  class Configuration::NullField < Blacklight::Configuration::Field
    def initialize(field)
      super(field: field)
    end
  end
end
