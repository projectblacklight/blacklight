module Blacklight::Solr::Document
  
  autoload :MARC, 'blacklight/solr/document/marc'
  
  # When this module is included,
  # it includes the RSolr::Ext::Doc module (provides the #find method etc..)
  def self.included(base)
    base.send :include, RSolr::Ext::Model
    base.extend DefaultFinders
    base.extend ExtendableClassMethods

    # Provide a class-level hash for extension parameters
    base.class_eval do
      def self.extension_parameters
        @@extension_parameters ||= {}
      end    
    end

    # after_initialize hook comes from RSolr::Ext::Model, I think.
    # We need to make sure all extensions get applied.
    base.after_initialize do 
      apply_extensions 
    end
  end



  ##Extensions framework, allowing the addition of document extensions
  # with behavior that only applies to certain specific extensions,
  # based on conditions. 


  # Needs to be called in initializer of class including this module, to
  # apply all registered extensions on a per-document basis
  def apply_extensions
    self.class.registered_extensions.each do | registration|
      self.extend( registration[:module_obj] ) if registration[:condition_proc].nil? || registration[:condition_proc].call( self )
    end
  end

  ## Exportable formats framework. TODO: Documentation note on relationship
  # between short_name and Rails Mime::Type.  The short name HAS to be
  # registered with Rails Mime::Type, so we register it here if not.
  # But much better to register it yourself, somehow. 
  #
  def will_export_as(short_name, content_type = nil)
    #Lookup in Rails Mime::Type, register if needed, otherwise take
    # content-type from registration if needed. This uses
    # some 'api' to Mime::Type that may or may not be entirely
    # public, the fact that a Mime::CONST is registered for every
    # type. But that's the only way to do the kind of check we need, sorry.
    begin
      mime_type = "Mime::#{short_name.to_s.upcase}".constantize
      content_type = mime_type.to_s unless content_type      
    rescue NameError
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
    exports_as[short_name] =  {:content_type => content_type}
  end

  # Collects formats that this doc can export as.
  # Returns a hash, keys are format short-names that can
  # be exported. Hash includes:
  #  :content-type => mime-content-type
  #  maybe more later
  def exports_as
    @exports_as ||= {}
  end

  # Call with a format shortname, export_as(:marc), simply returns
  # #export_as_marc . Later we may expand the design to allow you
  # to register an arbitrary method name instead of insisting
  # on the convention, so clients should call this method so
  # they'll still keep working if we do that. 
  def export_as(short_name)
    send("export_as_#{short_name.to_s}")
  end

  # Certain class-level modules needed for the document-specific
  # extendability architecture
  module ExtendableClassMethods
    attr_writer :registered_extensions
    def registered_extensions
      @registered_extensions ||= []
    end

    def use_extension( module_obj, &condition )
      registered_extensions << {:module_obj => module_obj, :condition_proc => condition}    
    end
  end
  
  # These methods get mixed into SolrDocument as class-level methods:
  #   SolrDocument.find_by_id(:id=>1) etc.
  module DefaultFinders
    
    # add a default_params accessor to whatever class that extends this module.
    # Example: SolrDocument.default_params
    def self.extended(b)
      b.cattr_accessor :default_params
      b.default_params = {}
    end
    
    # sends a request for finding one doc
    # the :id param key is requried
    # :rows defaults to 1
    # yields the final param hash before sending to solr
    # returns a RSolr::Ext::Response object
    def find_by_id(params, &blk)
      raise ':id param required!' unless params[:id]
      p = merge_defaults(:find_by_id, params)
      p[:rows] = 1
      yield p if block_given?
      self.find(p)
    end
    
    # sends a request for searching (multiple docs)
    # yields the final param hash before sending to solr
    # returns a RSolr::Ext::Response object
    def search(params, &blk)
      p = merge_defaults(:search, params)
      yield p if block_given?
      self.find(p)
    end
    
    #
    # helper methods -->
    #
    
    # shortcut method to SolrDocument.default_params[<method>]
    # returns an empty hash if the key was not set
    def default_params_for(method)
      self.default_params[method] || {}
    end
    
    # based on the method name set in SolrDocument.default_params[<method>]
    # this method merges those param into the "params" hash argument
    # and returns a copy
    def merge_defaults(method, params)
      default_params_for(method).deep_merge_unless_blank(params)
    end
    
  end
  
end
