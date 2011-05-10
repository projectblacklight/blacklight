require 'rsolr'
require 'rsolr-ext'
##
##
# = Introduction
# Blacklight::Solr::Document is the module with logic for a class representing
# an individual document returned from Solr results.  It can be added in to any
# local class you want, but in default Blacklight a SolrDocument class is
# provided for you which is pretty much a blank class "include"ing
# Blacklight::Solr::Document.
#
# Blacklight::Solr::Document mixes in Rsolr::Ext::Model to the calling class.
# It also provides some DefaultFinders.
#
# It also provides support for Document Extensions, which advertise supported
# transformation formats.
#
# = Document Extensions
# An Blacklight::Solr::Document extension is simply a ruby module which is mixed
# in to individual Document instances.  The intended use case is for documents
# containing some particular format of source material, such as Marc. An
# extension can be registered with your document class, along with a block
# containing custom logic for which documents to apply the extension to.
#
# SolrDocument.use_extension(MyExtension) {|document| my_logic_on_document(document}
#
# MyExtension will be mixed-in (using ruby 'extend') only to those documents
# where the block results in true.
#
# == Transformation conventions
# The main use case for extensions is for transforming a Document to another
# format. Either to another type of Ruby object, or to an exportable string in
# a certain format. 
#
# The convention for methods contained in extensions that transform to a ruby
# object is "to_*".  For instance, "to_marc" would return a Ruby Marc object.
#
# The convention for methods contained in extensions that transform to an
# exportable file of some kind is "export_as_*".  For instance,
# "export_as_marc21" would return a String object containing valid marc21, and
# "export_as_marcxml" would return a String object containing valid marcxml.
#
# The tokens used after "export_as" should normally be the format names as
# registered with Rails Mime::Type.
#
# == Advertising export formats
#
# If an extension advertises what export formats it can provide, than those
# formats will automatically be delivered by the Blacklight catalog/show
# controller, and potentially automatically advertised in various places
# that advertise available formats. (UnAPI; HTML link rel=alternate; Atom 
# link rel=alterate; etc).
#
# Export formats are 'registered' by calling the #will_export_as method
# on a Document instance. An extension would usually do this in a
# self.extended method, so it can be called on Documents that have
# the given extension added to them. For instance:
#
#   module DemoMarcExtension
#     def self.extended(document)
#       document.will_export_as(:marc21, "application/marc")
#       document.will_export_as(:marcxml, "application/marcxml+xml")
#     end
#
#     def export_as_marc21 ; something ; end
#     def export_as_marcxml ; something ; end
#   end
#
# == Extension Parameters
# Every class that includes Blacklight::Solr::Document gets a
# #extension_parameters method for saving arbitrary parameters on class-wide
# level that can be retrieved by extensions. These are arbitrary, just
# conventions with a given extension. For instance:
# SolrDocument.extension_parameters[:marc_source_field] = "solr_stored_field_name"
#
module Blacklight::Solr::Document
  autoload :Marc, 'blacklight/solr/document/marc'
  autoload :MarcExport, 'blacklight/solr/document/marc_export'
  autoload :DublinCore, 'blacklight/solr/document/dublin_core'
  autoload :Email, 'blacklight/solr/document/email'
  autoload :Sms, 'blacklight/solr/document/sms'
  
  def self.included(base)      
    base.send :include, RSolr::Ext::Model
    base.send :extend,  ClassMethods
   
    # after_initialize hook comes from RSolr::Ext::Model, I think.
    # We need to make sure all extensions get applied.
    base.after_initialize do 
       apply_extensions 
    end
  end    
    

    # Needs to be called in initializer of class including this module, to
    # apply all registered extensions on a per-document basis
    def apply_extensions
      self.class.registered_extensions.each do | registration|
        self.extend( registration[:module_obj] ) if registration[:condition_proc].nil? || registration[:condition_proc].call( self )
      end
    end
    
    ##  
    # Register exportable formats supported by the individual document.
    # Usually called by an extension in it's self.extended method, to
    # register the formats that extension can export. 
    # 
    # some_document.will_export_as(:some_format, "application/type") means
    # that the document (usually via an extension) has a method
    # "export_as_some_format" which returns a String of content that
    # is described by the mime content_type given. 
    # 
    # The format name should ideally _already_ be registered with
    # Rails Mime::Type, in your application initializer, representing
    # the content type given.  However, this method will attempt to
    # register it using Mime::Type.register_alias if it's not previously
    # registered. This is a bit sketchy though. 
    def will_export_as(short_name, content_type = nil)
      #Lookup in Rails Mime::Type, register if needed, otherwise take
      # content-type from registration if needed. This uses
      # some 'api' to Mime::Type that may or may not be entirely
      # public, the fact that a Mime::CONST is registered for every
      # type. But that's the only way to do the kind of check we need, sorry.
      begin      
        mime_type = "Mime::#{short_name.to_s.upcase}".constantize
        content_type = mime_type.to_s unless content_type      
      rescue NameError,LoadError
        # not registered, we need to register. Use register_alias to be least
        # likely to interfere with host app. 
        Mime::Type.register_alias(content_type, short_name)
      end
      
      # if content_type is nil, look it up from Rails Mime::Type
      if content_type.nil?
        # Accurate lookup in Rails Mime::Type is kind of pain, it doesn't
        # really provide the right API.
        if defined?(type_const_name)
          content_type = type_const_name.constantize.to_s
        end    
      end    
      export_formats[short_name] =  {:content_type => content_type}
    end
    
    # Collects formats that this doc can export as.
    # Returns a hash, keys are format short-names that can
    # be exported. Hash includes:
    #  :content-type => mime-content-type
    #  maybe more later
    # To see if a given export format is supported by this document,
    # simply call document.export_formats.keys.include?(:my_format)
    # Then call #export_as! to do the export. 
    def export_formats
      @export_formats ||= {}
    end
    
    # Call with a format shortname, export_as(:marc), simply returns
    # #export_as_marc . Later we may expand the design to allow you
    # to register an arbitrary method name instead of insisting
    # on the convention, so clients should call this method so
    # they'll still keep working if we do that. 
    def export_as(short_name)
      send("export_as_#{short_name.to_s}")
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
    attr_writer :registered_extensions
    
    # Returns array of hashes of registered extensions. Each hash
    # has a :module_obj key and a :condition_proc key. Usually this
    # method is only used internally in #apply_extensions, but if you
    # want to zero out all previously registered extensions you can call:
    # SolrDocument.registered_extensions = nil
    def registered_extensions
      @registered_extensions ||= []
    end

    def extension_parameters
      @extension_parameters ||= {}
    end      
        
    # Register an extension module with the class. A block taking one
    # parameter can be supplied; the block will be passed an instance of 
    # a Document, and the extension will be applied only if the block
    # evaluates as true. If no condition is given, the extension will
    # be applied to every instance of the class.
    #
    # SolrDocument.use_extension( SomeExtensionModule ) { | document | should_apply_some_extension?(document) }
    # SolrDocument.use_extension( SomeExtensionModule) # will be applied to all docs
    def use_extension( module_obj, &condition )
      registered_extensions << {:module_obj => module_obj, :condition_proc => condition}    
    end

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
