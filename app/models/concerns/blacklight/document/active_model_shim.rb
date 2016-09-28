# frozen_string_literal: true
require 'active_model/conversion'

module Blacklight::Document
  module ActiveModelShim
    extend ActiveSupport::Concern

    include ::ActiveModel::Conversion

    module ClassMethods
      def primary_key
        unique_key
      end

      def base_class
        self
      end

      def repository
        Blacklight.default_index
      end

      def find id
        repository.find(id).documents.first
      end
    end
    
    ##
    # Unique ID for the document
    def id
      self[self.class.unique_key]
    end

    def _read_attribute(attr)
      self[attr]
    end

    ##
    # ActiveRecord::Persistence method stubs to get non-AR objects to
    # play nice with e.g. Blacklight's bookmarks
    def persisted?
      true
    end

    def destroyed?
      false
    end
    
    def new_record?
      false
    end

    def marked_for_destruction?
      false
    end

    ##
    # #to_partial_path is also defined in Blacklight::Document, but
    # ActiveModel::Conversion (included above) will overwrite that..
    def to_partial_path
      'catalog/document'
    end
  end
end
