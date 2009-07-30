# add this directory to the load path if it hasn't already been added

lambda { |base|
  $: << base unless $:.include?(base) || $:.include?(File.expand_path(base))
}.call(File.dirname(__FILE__))

unless defined?(Mash)
  require 'mash'
end

unless Hash.respond_to?(:to_mash)
  class Hash
    def to_mash
      Mash.new(self)
    end
  end
end

require 'rubygems'
require 'rsolr'

module RSolr
  
  module Ext
    
    VERSION = '0.7.35'
    
    autoload :Request, 'rsolr-ext/request.rb'
    autoload :Response, 'rsolr-ext/response.rb'
    autoload :Mapable, 'rsolr-ext/mapable.rb'
    autoload :Findable, 'rsolr-ext/findable.rb'
    autoload :Doc, 'rsolr-ext/doc.rb'
    
    # RSolr::Ext.map_params({})
    def self.map_params(r)
      RSolr::Ext::Request::Standard.new.map(r)
    end
    
    # RSolr::Ext.wrap_response({})
    def self.wrap_response(r)
      RSolr::Ext::Response::Standard.new(r)
    end
    
    # c = RSolr::Ext.connect
    # c.find(:q=>'*:*').docs.size
    def self.connect(*args)
      connection = RSolr.connect(*args)
      connection.extend RSolr::Ext::Findable
      connection
    end
    
  end
  
end