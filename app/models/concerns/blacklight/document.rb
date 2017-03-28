# frozen_string_literal: true

##
##
# = Introduction
# Blacklight::Document is the module with logic for a class representing
# an individual document returned from Solr results.  It can be added in to any
# local class you want, but in default Blacklight a SolrDocument class is
# provided for you which is pretty much a blank class "include"ing
# Blacklight::Document.
#
# Blacklight::Document provides some DefaultFinders.
#
# It also provides support for Document Extensions, which advertise supported
# transformation formats.
#
module Blacklight::Document
  autoload :ActiveModelShim, 'blacklight/document/active_model_shim'
  autoload :SchemaOrg, 'blacklight/document/schema_org'
  autoload :CacheKey, 'blacklight/document/cache_key'
  autoload :DublinCore, 'blacklight/document/dublin_core'
  autoload :Email, 'blacklight/document/email'
  autoload :SemanticFields, 'blacklight/document/semantic_fields'
  autoload :Sms, 'blacklight/document/sms'
  autoload :Extensions, 'blacklight/document/extensions'
  autoload :Export, 'blacklight/document/export'

  extend ActiveSupport::Concern
  include Blacklight::Document::SchemaOrg
  include Blacklight::Document::SemanticFields
  include Blacklight::Document::CacheKey
  include Blacklight::Document::Export

  included do
    extend ActiveModel::Naming
    include Blacklight::Document::Extensions
    include GlobalID::Identification
  end

  attr_reader :response, :_source
  alias_method :solr_response, :response

  delegate :[], :key?, :keys, :to_h, :as_json, to: :_source

  def initialize(source_doc = {}, response = nil)
    @_source = ActiveSupport::HashWithIndifferentAccess.new(source_doc).freeze
    @response = response
    apply_extensions
  end

  # Helper method to check if value/multi-values exist for a given key.
  # The value can be a string, or a RegExp
  # Multiple "values" can be given; only one needs to match.
  #
  # Example:
  # doc.has?(:location_facet)
  # doc.has?(:location_facet, 'Clemons')
  # doc.has?(:id, 'h009', /^u/i)
  def has?(k, *values)
    if !key?(k)
      false
    elsif values.empty?
      self[k].present?
    else
      Array(values).any? do |expected|
        Array(self[k]).any? do |actual|
          case expected
          when Regexp
            actual =~ expected
          else
            actual == expected
          end
        end
      end
    end
  end
  alias has_field? has?
  alias has_key? key?

  def fetch key, *default
    if key? key
      self[key]
    elsif default.empty? && !block_given?
      raise KeyError, "key not found \"#{key}\""
    else
      (yield(self) if block_given?) || default.first
    end
  end

  def first key
    Array(self[key]).first
  end

  def to_partial_path
    'catalog/document'
  end

  def has_highlight_field? _k
    false
  end

  def highlight_field _k
    nil
  end

  ##
  # Implementations that support More-Like-This should override this method
  # to return an array of documents that are like this one.
  def more_like_this
    []
  end

  # Certain class-level methods needed for the document-specific
  # extendability architecture
  module ClassMethods
    attr_writer :unique_key
    def unique_key
      @unique_key ||= 'id'
    end
  end
end
