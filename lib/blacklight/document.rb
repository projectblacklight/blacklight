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
  autoload :SchemaOrg, 'blacklight/document/schema_org'
  autoload :DublinCore, 'blacklight/document/dublin_core'
  autoload :Email, 'blacklight/document/email'
  autoload :SemanticFields, 'blacklight/document/semantic_fields'
  autoload :Sms, 'blacklight/document/sms'
  autoload :Extensions, 'blacklight/document/extensions'
  autoload :Export, 'blacklight/document/export'

  extend ActiveSupport::Concern
  include Blacklight::Document::SchemaOrg
  include Blacklight::Document::SemanticFields
  include Blacklight::Document::Export

  included do
    extend ActiveModel::Naming
    include Blacklight::Document::Extensions
  end    

  attr_reader :response, :_source
  alias_method :solr_response, :response

  def initialize(source_doc={}, response=nil)
    @_source = source_doc.with_indifferent_access
    @response = response
    apply_extensions
  end

  def to_model
    self
  end

  def persisted?
    true
  end

  # the wrapper method to the @_source object.
  # If a method is missing, it gets sent to @_source
  # with all of the original params and block
  def method_missing(m, *args, &b)
    if _source and _source.respond_to? m
      _source.send(m, *args, &b)
    else
      super
    end
  end

  def respond_to_missing? *args
    (_source && _source.respond_to?(*args)) || super
  end

  def [] *args
    _source.send :[], *args
  end

  def _read_attribute(attr)
    self[attr]
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
    return true if key?(k) and values.empty?
    return false if self[k].nil?
    target = self[k]
    if target.is_a?(Array)
      values.each do |val|
        return target.any?{|tv| val.is_a?(Regexp) ? (tv =~ val) : (tv==val)}
      end
    else
      return values.any? {|val| val.is_a?(Regexp) ? (target =~ val) : (target == val)}
    end
  end

  def key? k
    _source.key? k
  end

  # helper
  # key is the name of the field
  # opts is a hash with the following valid keys:
  #  - :sep - a string used for joining multivalued field values
  #  - :default - a value to return when the key doesn't exist
  # if :sep is nil and the field is a multivalued field, the array is returned
  def get(key, opts={:sep=>', ', :default=>nil})
    if key? key
      val = self[key]
      (val.is_a?(Array) and opts[:sep]) ? val.join(opts[:sep]) : val
    else
      opts[:default]
    end
  end

  def first key
    Array(self[key]).first
  end

  def id
    self[self.class.unique_key]
  end

  def to_param
    id.to_s
  end

  def as_json(options = nil)
    _source.as_json(options)
  end

  def to_partial_path
    'catalog/document'
  end

  def destroyed?
    false
  end
  
  def new_record?
    false
  end
  
  def has_highlight_field? k
    false
  end

  def highlight_field k
    nil
  end


  # Certain class-level methods needed for the document-specific
  # extendability architecture
  module ClassMethods

    attr_writer :unique_key
    def unique_key
      @unique_key ||= 'id' 
    end

    def primary_key
      unique_key
    end
    
    def base_class
      self
    end  
  end
end
