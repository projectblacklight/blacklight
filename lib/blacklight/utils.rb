require 'ostruct'
module Blacklight
  class OpenStructWithHashAccess < OpenStruct
    delegate :keys, :has_key?, :delete, :length, :reject!, :select!, :include, :fetch, :to => :to_h

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

  class NestedOpenStructWithHashAccess < OpenStructWithHashAccess
    attr_reader :nested_class
    delegate :default_proc=, :to => :to_h

    def initialize klass, *args
      @nested_class = klass
      hash = {}

      hashes_and_keys = args.flatten
      lazy_configs = hashes_and_keys.extract_options!

      args.each do |v|
        if v.is_a? Hash
          key = v.first
          value = v[key]

          hash[key] = nested_class.new value
        else
          hash[v] = nested_class.new
        end
      end

      lazy_configs.each do |k,v|
        hash[k] = nested_class.new v
      end

      super hash
      set_default_proc!
    end

    def << key
      @table[key]
    end

    def []=(key, value)
      if value.is_a? Hash
        send "#{key}=", nested_class.new(value)
      else
        send "#{key}=", value
      end
    end

    def marshal_dump
      h = to_h.dup
      h.default = nil

      [nested_class, h]
    end

    def marshal_load x
      @nested_class = x.first
      super x.last
      set_default_proc!
    end

    private
    def set_default_proc!
      self.default_proc = lambda do |hash, key|
        hash[key] = self.nested_class.new
      end
    end
  end
end
