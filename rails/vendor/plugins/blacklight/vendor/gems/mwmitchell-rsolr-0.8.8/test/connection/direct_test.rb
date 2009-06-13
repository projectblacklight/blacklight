if defined?(JRUBY_VERSION)
  
  require 'helper'
  require 'connection/test_methods'
  
  class ConnectionDirectTest < RSolrBaseTest
    
    include ConnectionTestMethods
    
    def setup
      base = File.expand_path( File.dirname(__FILE__) )
      dist = File.join(base, '..', '..', 'apache-solr')
      home = File.join(dist, 'example', 'solr')
      @solr = RSolr.connect(:adapter=>:direct, :home_dir=>home, :dist_dir=>dist)
      @solr.delete_by_query('*:*')
      @solr.commit
    end
    
    def teardown
      @solr.adapter.close
    end
    
  end
  
end