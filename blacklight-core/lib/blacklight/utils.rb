require 'ostruct'
module Blacklight
  class OpenStructWithHashAccess < OpenStruct
    delegate :keys, :merge, :to => :to_h

    def []=(key, value)
      send "#{key}=", value
    end

    def [](key)
      send key
    end

    def to_h
      @table
    end
  end
end
