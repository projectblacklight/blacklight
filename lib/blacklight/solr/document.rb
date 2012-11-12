# -*- encoding : utf-8 -*-
require 'rsolr'
##
##
# = Introduction
# Blacklight::Solr::Document is the module with logic for a class representing
# an individual document returned from Solr results.  It can be added in to any
# local class you want, but in default Blacklight a SolrDocument class is
# provided for you which is pretty much a blank class "include"ing
# Blacklight::Solr::Document.
#
# Blacklight::Solr::Document provides some DefaultFinders.
#
# It also provides support for Document Extensions, which advertise supported
# transformation formats.
#

module Blacklight::Solr::Document
  autoload :Marc, 'blacklight/solr/document/marc'
  autoload :MarcExport, 'blacklight/solr/document/marc_export'
  autoload :DublinCore, 'blacklight/solr/document/dublin_core'
  autoload :Email, 'blacklight/solr/document/email'
  autoload :Sms, 'blacklight/solr/document/sms'
  autoload :Extensions, 'blacklight/solr/document/extensions'
  autoload :Export, 'blacklight/solr/document/export'
  autoload :MoreLikeThis, 'blacklight/solr/document/more_like_this'

  extend ActiveSupport::Concern
  include Blacklight::Solr::Document::Export
  include Blacklight::Solr::Document::MoreLikeThis

  included do
    extend ActiveModel::Naming
    include Blacklight::Solr::Document::Extensions
  end    

  attr_reader :solr_response

  def initialize(source_doc={}, solr_response=nil)
    @_source = source_doc.with_indifferent_access
    @solr_response = solr_response
    apply_extensions
  end

  # the wrapper method to the @_source object.
  # If a method is missing, it gets sent to @_source
  # with all of the original params and block
  def method_missing(m, *args, &b)
    @_source.send(m, *args, &b)
  end

  def [] *args
    @_source.send :[], *args
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
    return if @_source[k].nil?
    return true if @_source.key?(k) and values.empty?
    target = @_source[k]
    if target.is_a?(Array)
      values.each do |val|
        return target.any?{|tv| val.is_a?(Regexp) ? (tv =~ val) : (tv==val)}
      end
    else
      return values.any? {|val| val.is_a?(Regexp) ? (target =~ val) : (target == val)}
    end
  end

  def has_highlight_field? k
    return false if @solr_response['highlighting'].blank? or @solr_response['highlighting'][self.id].blank?
    
    @solr_response['highlighting'][self.id].key? k.to_s
  end

  def highlight_field k
    return nil unless has_highlight_field? k
    @solr_response['highlighting'][self.id][k.to_s].map { |x| x.html_safe }

  end

  # helper
  # key is the name of the field
  # opts is a hash with the following valid keys:
  #  - :sep - a string used for joining multivalued field values
  #  - :default - a value to return when the key doesn't exist
  # if :sep is nil and the field is a multivalued field, the array is returned
  def get(key, opts={:sep=>', ', :default=>nil})
    if @_source.key? key
      val = @_source[key]
      (val.is_a?(Array) and opts[:sep]) ? val.join(opts[:sep]) : val
    else
      opts[:default]
    end
  end

  def id
    self[self.class.unique_key]
  end

  def to_param
    id
  end

  def to_partial_path
    'catalog/document'
  end

   
  # Returns a hash keyed by semantic tokens (see ExtendableClassMethods#semantic_fields), value is an array of
  # strings. (Array to handle multi-value fields). If no value(s)
  # available, empty array is returned. 
  #
  # Default implementation here uses ExtendableClassMethods#semantic_fields
  # to just take values from Solr stored fields. 
  # Extensions can over-ride this method to provide better/different lookup,
  # but extensions should call super and modify hash returned, to avoid
  # unintentionally erasing values provided by other extensions. 
  def to_semantic_values
    unless @semantic_value_hash
      @semantic_value_hash = Hash.new([]) # default to empty array   
      self.class.field_semantics.each_pair do |key, solr_field|
        value = self[solr_field]
        # Make single and multi-values all arrays, so clients
        # don't have to know.
        unless value.nil?
          value = [value] unless value.kind_of?(Array)      
          @semantic_value_hash[key] = value
        end
      end
    end
    return @semantic_value_hash
  end
  
  
  # Certain class-level methods needed for the document-specific
  # extendability architecture
  module ClassMethods

    attr_writer :unique_key
    def unique_key
      # XXX Blacklight.config[:unique_key] should be deprecated soon
      @unique_key ||= Blacklight.config[:unique_key] if Blacklight.respond_to?(:config) and Blacklight.config[:unique_key]
      @unique_key ||= 'id' 

      @unique_key
    end

     def connection
      @connection ||= Blacklight.solr
     end
    
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
  
 
  
end
