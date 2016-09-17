# frozen_string_literal: true
module Blacklight::Document
  module SemanticFields
    extend ActiveSupport::Concern

    module ClassMethods
      # Returns array of hashes of registered extensions. Each hash
      # has a :module_obj key and a :condition_proc key. Usually this
      # method is only used internally in #apply_extensions, but if you

      # Class-level method for accessing/setting semantic mappings
      # for solr stored fields. Can be set by local app, key is
      # a symbol for a semantic, value is a solr _stored_ field.
      #
      # Stored field can be single or multi-value. In some cases
      # clients may only use the first value from a multi-value field.
      #
      # Currently documented semantic tokens, not all may be
      # used by core BL, but some may be used by plugins present
      # or future.
      # :title, :author, :year, :language => User-presentable strings.
      def field_semantics
        @field_semantics ||= {}
      end
    end

    # Returns a hash keyed by semantic tokens, value is an array of
    # strings. (Array to handle multi-value fields). If no value(s)
    # available, empty array is returned.
    #
    # Default implementation here uses field_semantics
    # to just take values from Solr stored fields.
    # Extensions can over-ride this method to provide better/different lookup,
    # but extensions should call super and modify hash returned, to avoid
    # unintentionally erasing values provided by other extensions.
    def to_semantic_values
      @semantic_value_hash ||= self.class.field_semantics.each_with_object(Hash.new([])) do |(key, field_name), hash|
        value = self[field_name]

        # Make single and multi-values all arrays, so clients
        # don't have to know.
        hash[key] = Array.wrap(value) unless value.nil?
      end

      @semantic_value_hash ||= {}
    end
  end
end
