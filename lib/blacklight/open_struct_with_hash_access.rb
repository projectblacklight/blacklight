# frozen_string_literal: true

require 'ostruct'
module Blacklight
  ##
  # An OpenStruct that responds to common Hash methods
  class OpenStructWithHashAccess < OpenStruct
    delegate :keys, :each, :map, :has_key?, :key?, :include?, :empty?,
             :length, :delete, :delete_if, :keep_if, :clear, :reject!, :select!,
             :replace, :fetch, :to_json, :as_json, :any?, :freeze, :unfreeze, :frozen?, to: :to_h

    ##
    # Expose the internal hash
    # @return [Hash]
    def to_h
      @table
    end

    def select(...)
      self.class.new to_h.select(...)
    end

    def sort_by(...)
      self.class.new to_h.sort_by(...).to_h
    end

    def sort_by!(...)
      replace to_h.sort_by(...).to_h
      self
    end

    ##
    # Merge the values of this OpenStruct with another OpenStruct or Hash
    # @param [Hash,#to_h] other_hash
    # @return [OpenStructWithHashAccess] a new instance of an OpenStructWithHashAccess
    def merge other_hash
      self.class.new to_h.merge((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    ##
    # Merge the values of another OpenStruct or Hash into this object
    # @param [Hash,#to_h] other_hash
    # @return [OpenStructWithHashAccess] a new instance of an OpenStructWithHashAccess
    def merge! other_hash
      @table.merge!((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    def reverse_merge(other_hash)
      self.class.new to_h.reverse_merge((other_hash if other_hash.is_a? Hash) || other_hash.to_h)
    end

    def deep_dup
      self.class.new @table.deep_dup
    end

    def deep_transform_values(&method)
      self.class.new @table.deep_transform_values(&method)
    end

    def try(method_name = nil, *args, &block)
      if method_name.nil? && block_given?
        if b.arity.zero?
          instance_eval(&block)
        else
          yield self
        end
      elsif respond_to?(method_name)
        public_send(method_name, *args, &b)
      end
    end
  end
end
