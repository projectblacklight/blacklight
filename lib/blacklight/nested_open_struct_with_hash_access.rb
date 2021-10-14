# frozen_string_literal: true
require 'ostruct'
module Blacklight
  ##
  # An OpenStruct refinement that converts any hash-keys into
  # additional instances of NestedOpenStructWithHashAccess
  class NestedOpenStructWithHashAccess < OpenStructWithHashAccess
    extend Deprecation
    self.deprecation_horizon = 'blacklight 8.0'

    attr_reader :nested_class

    delegate :default_proc=, to: :to_h

    def initialize(klass, hash = {})
      @nested_class = klass
      value = hash.each_with_object({}) do |(k, v), h|
        h[k] = if v.is_a? Hash
                 nested_class.new({ key: k.to_sym }.merge(v))
               else
                 v
               end
      end

      super value
      set_default_proc!
    end

    ##
    # Add an new key to the object, with a default default
    def << key
      @table[key]
    end

    ##
    # Add a new key/value to the object; if it's a Hash, turn it
    # into another NestedOpenStructWithHashAccess
    def []=(key, value)
      if value.is_a? Hash
        send "#{key}=", nested_class.new({ key: key.to_sym }.merge(value))
      else
        super
      end
    end

    ##
    # Before serializing, we need to reset the default proc
    # so it can be serialized appropriately
    def marshal_dump
      h = to_h.dup
      h.default = nil

      [nested_class, h]
    end

    ##
    # After deserializing, we need to re-add the default proc
    # to the internal hash
    def marshal_load x
      @nested_class = x.first
      super x.last
      set_default_proc!
    end

    def deep_dup
      self.class.new nested_class, @table.deep_dup
    end

    def select *args, &block
      self.class.new nested_class, to_h.select(*args, &block)
    end

    ##
    # Merge the values of this OpenStruct with another OpenStruct or Hash
    # @param [Hash,#to_h] other_hash
    # @return [OpenStructWithHashAccess] a new instance of an OpenStructWithHashAccess
    def merge other_hash
      self.class.new nested_class, to_h.merge((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    ##
    # Merge the values of another OpenStruct or Hash into this object
    # @param [Hash,#to_h] other_hash
    # @return [OpenStructWithHashAccess] a new instance of an OpenStructWithHashAccess
    def merge! other_hash
      @table.merge!(nested_class, (other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    ##
    # Override #method_missing from OpenStruct to ensure the default_proc logic
    # gets triggered.
    def method_missing(mid, *args, **kwargs, &block)
      len = args.length

      res = if mid.to_s.end_with?('!')
              m = mid[0...-1].to_sym
              new_ostruct_member!(m)
              @table[m]
            elsif mid.to_s.end_with?('=')
              m = mid[0...-1].to_sym
              new_ostruct_member!(m)
              @table[m] = args.first
            elsif len.zero? && kwargs.blank? && !block
              Deprecation.warn(Blacklight::NestedOpenStructWithHashAccess,
                               "Initializing a #{nested_class} implicitly (by calling #{mid}) is deprecated. Call it as #{mid}! or pass initialize arguments")

              new_ostruct_member!(mid)
              @table[mid]
            else
              new_ostruct_member!(mid)
              @table[mid] = nested_class.new(key: mid, **(args.first || {}), **kwargs)
            end

      block&.call(res)

      res
    end

    private

    def set_default_proc!
      self.default_proc = lambda do |hash, key|
        hash[key] = nested_class.new(key: key)
      end
    end
  end
end
