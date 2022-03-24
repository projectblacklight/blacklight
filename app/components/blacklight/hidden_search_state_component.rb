# frozen_string_literal: true

module Blacklight
  # Writes out zero or more <input type="hidden"> elements, completely
  # representing a hash passed in using Rails-style request parameters
  # for hashes nested with arrays and other hashes.
  class HiddenSearchStateComponent < Blacklight::Component
    # @param [Hash] params
    def initialize(params:)
      @params = params.except(:page, :utf8)
    end

    def call
      hidden_fields = []
      flatten_hash(@params).each do |name, value|
        value = Array.wrap(value)
        value.each do |v|
          hidden_fields << hidden_field_tag(name, v.to_s, id: nil)
        end
      end

      safe_join(hidden_fields, "\n")
    end

    private

    def flatten_hash(hash = params, ancestor_names = [])
      flat_hash = {}
      hash.each do |k, v|
        names = Array.new(ancestor_names)
        names << k
        if v.is_a?(Hash)
          flat_hash.merge!(flatten_hash(v, names))
        else
          key = flat_hash_key(names)
          key += "[]" if v.is_a?(Array)
          flat_hash[key] = v
        end
      end

      flat_hash
    end

    def flat_hash_key(names)
      names = Array.new(names)
      name = names.shift.to_s.dup
      names.each do |n|
        name << "[#{n}]"
      end
      name
    end
  end
end
