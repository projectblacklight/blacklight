# add this directory to the load path if it hasn't already been added

$: << File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__))

unless Array.respond_to?(:extract_options!)
  class Array
    def extract_options!
      last.is_a?(::Hash) ? pop : {}
    end
  end
end

module RSolr
  
  VERSION = '0.8.8'
  
  autoload :Message, 'rsolr/message'
  autoload :Connection, 'rsolr/connection'
  autoload :Adapter, 'rsolr/adapter'
  autoload :HTTPClient, 'rsolr/http_client'
  
  # factory for creating connections
  # "options" is a hash that gets used by the Connection
  # object AND the adapter object.
  def self.connect(options={})
    adapter_name = options[:adapter] ||= :http
    types = {
      :http=>'HTTP',
      :direct=>'Direct'
    }
    adapter_class = RSolr::Adapter.const_get(types[adapter_name])
    adapter = adapter_class.new(options)
    RSolr::Connection.new(adapter, options)
  end
  
  # A module that contains string related methods
  module Char
    
    # escape - from the solr-ruby library
    # RSolr.escape('asdf')
    # backslash everything that isn't a word character
    def escape(value)
      value.gsub(/(\W)/, '\\\\\1')
    end
    
  end
  
  # send the escape method into the Connection class ->
  # solr = RSolr.connect
  # solr.escape('asdf')
  RSolr::Connection.send(:include, Char)
  
  # bring escape into this module (RSolr) -> RSolr.escape('asdf')
  extend Char
  
  # RequestError is a common/generic exception class used by the adapters
  class RequestError < RuntimeError; end
  
end