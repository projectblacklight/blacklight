# frozen_string_literal: true
module Blacklight
  class Configuration::ToolConfig < OpenStructWithHashAccess
    # @!attribute partial

    def name
      super || key
    end
  end
end
