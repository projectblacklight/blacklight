# frozen_string_literal: true

require 'active_model/conversion'

module Blacklight::Document
  module Attributes
    extend ActiveSupport::Concern

    included do
      class_attribute :attribute_types, instance_accessor: false
      self.attribute_types = Hash.new(Blacklight::Types::Value)
    end

    class_methods do
      # Define an attribute reader on a document model
      # @param [Symbol] name the name of the attribute to define
      # @param [Symbol, Class] type the type of the attribute to define
      # @param [String] field the name of the document's field to use for this attribute
      # @param [any, Proc] default the default value for the attribute
      # @example
      #   class SolrDocument
      #     include Blacklight::Solr::Document
      #     attribute :title, Blacklight::Types::String, 'title_tesim'
      #   end
      #
      #   doc = SolrDocument.new(title_tesim: ["One flew over the cuckoo's nest"])
      #   doc.title
      #   #=> "One flew over the cuckoo's nest"
      def attribute(name, type = :value, deprecated_field = name, field: nil, default: Blacklight::Document::NO_DEFAULT_PROVIDED, **kwargs)
        field ||= deprecated_field

        define_method name do
          if type.respond_to?(:coerce) && !(type < Blacklight::Types::Value)
            # deprecated behavior using a bespoke api
            type.coerce(fetch(field, default))
          else
            # newer behavior better aligned with ActiveModel::Type
            instance = Blacklight::Types.lookup(type, **kwargs) if type.is_a? Symbol
            instance ||= type.new(**kwargs)

            instance.cast(fetch(field, default))
          end
        end
      end
    end
  end
end
