require 'ostruct'
module Blacklight
  class OpenStructWithHashAccess < OpenStruct
    delegate :keys, :reject!, :select!, :include, :fetch, :to => :to_h

    def []=(key, value)
      send "#{key}=", value
    end

    def [](key)
      send key
    end

    def to_h
      @table
    end

    def merge other_hash
      self.class.new to_h.merge((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    def merge! other_hash
      @table.merge!((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end 
  end
end
