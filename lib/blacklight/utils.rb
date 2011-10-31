require 'ostruct'
module Blacklight
  class OpenStructWithHashAccess < OpenStruct
    def []=(key, value)
      send "#{key}=", value
    end

    def [](key)
      send key
    end
  end
end
