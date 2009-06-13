unless defined?(JRUBY_VERSION)
  
  require 'helper'
  require 'connection/test_methods'
  
  class AdapterHTTPTest < RSolrBaseTest
  
    include ConnectionTestMethods
  
    def setup
      @solr = RSolr.connect
      @solr.delete_by_query('*:*')
      @solr.commit
    end
  
  end
  
end