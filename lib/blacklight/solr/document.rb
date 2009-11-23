module Blacklight::Solr::Document
  
  autoload :MARC, 'blacklight/solr/document/marc'
  
  # When this module is included,
  # it includes the RSolr::Ext::Doc module (provides the #find method etc..)
  def self.included(base)
    base.send :include, RSolr::Ext::Model
    base.extend DefaultFinders
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