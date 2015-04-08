require 'ostruct'
module Blacklight

  module Utils
    def self.needs_attr_accessible?
      if rails_3?
        !strong_parameters_enabled?
      else
        protected_attributes_enabled?
      end
    end

    def self.rails_3?
      Rails::VERSION::MAJOR == 3
    end

    def self.strong_parameters_enabled?
      defined?(ActionController::StrongParameters)
    end

    def self.protected_attributes_enabled?
      defined?(ActiveModel::MassAssignmentSecurity)
    end
  end

  ##
  # An OpenStruct that responds to common Hash methods
  class OpenStructWithHashAccess < OpenStruct
    delegate :keys, :each, :map, :has_key?, :key?, :include?, :empty?, :length, :delete, :delete_if, :keep_if, :clear, :reject!, :select!, :replace, :fetch, :to_json, :as_json, to: :to_h

    if ::RUBY_VERSION < '2.0'
      def []=(key, value)
        send "#{key}=", value
      end

      def [](key)
        send key
      end

      def respond_to? method, *args
        super(method, *args) || has_key?(method.to_sym)
      end
    end

    ##
    # Expose the internal hash
    # @return [Hash]
    def to_h
      @table
    end
    
    def select *args, &block
      self.class.new to_h.select(*args, &block)
    end

    def sort_by *args, &block
      self.class.new Hash[to_h.sort_by(*args, &block)]
    end

    def sort_by! *args, &block
      replace Hash[to_h.sort_by(*args, &block)]
      self
    end

    ##
    # Merge the values of this OpenStruct with another OpenStruct or Hash
    # @param [Hash,#to_h]
    # @return [OpenStructWithHashAccess] a new instance of an OpenStructWithHashAccess
    def merge other_hash
      self.class.new to_h.merge((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    ##
    # Merge the values of another OpenStruct or Hash into this object
    # @param [Hash,#to_h]
    # @return [OpenStructWithHashAccess] a new instance of an OpenStructWithHashAccess
    def merge! other_hash
      @table.merge!((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    def deep_dup
      self.class.new @table.deep_dup
    end
  end


  ##
  # An OpenStruct refinement that converts any hash-keys into  
  # additional instances of NestedOpenStructWithHashAccess
  class NestedOpenStructWithHashAccess < OpenStructWithHashAccess
    attr_reader :nested_class
    delegate :default_proc=, :to => :to_h

    def initialize klass, *args
      @nested_class = klass
      hash = {}

      hashes_and_keys = args.flatten
      lazy_configs = hashes_and_keys.extract_options!

      hashes_and_keys.each do |v|
        if v.is_a? Hash
          key = v.first
          value = v[key]

          hash[key] = nested_class.new value
        else
          hash[v] = nested_class.new
        end
      end

      lazy_configs.each do |k,v|
        if v.is_a? nested_class
          hash[k] = v
        else
          hash[k] = nested_class.new v
        end
      end

      super hash
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
        send "#{key}=", nested_class.new(value)
      elsif ::RUBY_VERSION < '2.0'
        send "#{key}=", value
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
      self.class.new self.nested_class, @table.deep_dup
    end

    def select *args, &block
      self.class.new nested_class, to_h.select(*args, &block)
    end

    ##
    # Merge the values of this OpenStruct with another OpenStruct or Hash
    # @param [Hash,#to_h]
    # @return [OpenStructWithHashAccess] a new instance of an OpenStructWithHashAccess
    def merge other_hash
      self.class.new nested_class, to_h.merge((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    ##
    # Merge the values of another OpenStruct or Hash into this object
    # @param [Hash,#to_h]
    # @return [OpenStructWithHashAccess] a new instance of an OpenStructWithHashAccess
    def merge! other_hash
      @table.merge!(nested_class, (other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end 

    private
    def set_default_proc!
      self.default_proc = lambda do |hash, key|
        hash[key] = self.nested_class.new
      end
    end
  end
end
