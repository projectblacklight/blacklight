module Blacklight
  class SolrConf < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    argument :target_path, :type=>:string, :default => "."
    
    desc """ 
Generate solr config files solrconfig.xml and schema.xml
to directory you specify. (default current dir).  

Conf files generated are set up to work with out-of-the-box default 
blacklight.

You might want to put them into a solr setup, or you might just
want to look at them.   

"""
    
    # this generator used by test jetty generator too. 
    def solr_conf_files
      copy_file "solr_conf/schema.xml", File.expand_path("./schema.xml", target_path)
      copy_file "solr_conf/solrconfig.xml", File.expand_path("./solrconfig.xml", target_path)
    end
  end
end
