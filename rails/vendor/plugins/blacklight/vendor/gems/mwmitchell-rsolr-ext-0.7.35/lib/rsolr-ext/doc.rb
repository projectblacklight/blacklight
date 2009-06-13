# include this module into a plain ruby class:
# class Book
#   include RSolr::Ext::Doc
#   connection = RSolr::Ext.connect
#   default_params = {:phrase_filters=>'type:book'}
# end
# 
# Then:
# number_10 = Book.find_by_id(10)
#
module RSolr::Ext::Doc
  
  # Class level methods for altering object instances
  module Callbacks
    
    # creates the @hooks container ("hooks" are blocks or procs).
    # returns an array
    def hooks
      @hooks ||= []
    end
    
    # method that only accepts a block
    # The block is executed when an object is created via #new -> SolrDoc.new
    # The blocks scope is the instance of the object.
    def after_initialize(&blk)
      hooks << blk
    end
    
    # Removes the current set of after_initialize blocks.
    # You would use this if you wanted to open a class back up,
    # but clear out the previously defined blocks.
    def clear_after_initialize_blocks!
      @hooks = []
    end
    
  end
  
  #
  # Findable is a module that gets mixed into the SolrDocument class object.
  # These methods will be available through the class like: SolrDocument.find and SolrDocument.find_by_id
  #
  module Findable
    
    attr_accessor :connection
    
    def connection
      @connection ||= RSolr::Ext.connect
    end
    
    def find(*args)
      mode, solr_params, opts = connection.send(:extract_find_opts!, *args)
      connection.find(*[mode, solr_params, opts]) { |doc| self.new(doc) }
    end
    
    def find_by_id(id, solr_params={}, opts={})
      connection.find_by_id(id, solr_params, opts) { |doc| self.new(doc) }
    end
    
  end
  
  # Called by Ruby Module API
  # extends this *class* object
  def self.included(base)
    base.extend Callbacks
    base.extend Findable
  end
  
  # The original object passed in to the #new method
  attr :_source_hash
  
  # The original object passed, converted to a mash
  attr :_source_mash
  
  # Constructor **for the class that is getting this module included**
  # source_doc should be a hash or something similar
  # calls each of after_initialize blocks
  def initialize(source_doc={})
    @_source_hash = source_doc
    @_source_mash = source_doc.to_mash
    self.class.hooks.each do |h|
      instance_eval &h
    end
  end
  
  # for easy access to the solr id (route helpers etc..)
  def id
    @_source_mash['id']
  end
  
  # the wrapper method to the @_source_hash object.
  # If a method is missing, it gets sent to @_source_hash
  # with all of the original params and block
  def method_missing(m, *args, &b)
    @_source_mash.send(m, *args, &b)
  end
  
end