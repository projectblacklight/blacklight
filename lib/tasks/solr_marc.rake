# Rake tasks for the SolrMarc Java indexer.
# Marc Record defaults to indexing lc_records.utf8.mrc
# config.properties defaults to config/demo_config.properties (in the plugin, not the rails app)


require 'fileutils'

namespace :solr do
  namespace :marc do
    
    def blah
      :blah
    end
    
    desc "Index the supplied test data into Solr; set NOOP to true to view output command."
    task :index_test_data do
      root = Rails.root
      marc_records_path = File.join(root, "test-data", "test_data.utf8.mrc")
      solr_path = File.join(root, "jetty", "solr")
      solr_war_path = File.join(root, 'jetty', 'webapps', 'solr.war')
      solr_marc_jar_path = File.join(root, 'solr_marc', 'SolrMarc.jar')
      config_path = File.join(root, 'config', 'SolrMarc', 'config.properties')
      indexer_properties_path = File.join(root, 'config', 'SolrMarc', 'index.properties')
      cmd = "java -Xmx512m"
      cmd << " -Dsolr.indexer.properties=#{indexer_properties_path} -Done-jar.class.path=#{solr_war_path} -Dsolr.path=#{solr_path}"
      cmd << " -jar #{solr_marc_jar_path} #{config_path} #{marc_records_path}"
      puts "\ncommand being executed:\n#{cmd}\n\n"
      system cmd unless ENV.keys.any?{|k| k =~ /noop/i }
    end
    
    desc "Index marc data using SolrMarc. Available environment variables: MARC_RECORDS_PATH, CONFIG_PATH, SOLR_MARC_MEM_ARGS, SOLR_WAR_PATH, SOLR_JAR_PATH"
    task :index => "index:work"

    namespace :index do

     # Calculate default args based on location of rake file itself,
     # which we assume to be in the plugin, in a demo app, or an
     # app set up like the demo app in relation to it's supporting tools.
    
      base_path = File.dirname(__FILE__)

      # Config, we take from app config if present (env-specific
      # if available) otherwise from config bundled with plugin
      default_config_path = File.join(RAILS_ROOT, "config", "SolrMarc", "config-#{ENV['RAILS_ENV'] || "development"}.properties")
      unless File.exists?(default_config_path)
        default_config_path = File.join(RAILS_ROOT, "config", "SolrMarc", "config.properties")
      end
      unless File.exists?( default_config_path )
        default_config_path = File.join(base_path, "../../config/SolrMarc/config.properties")              
      end
      default_config_path = File.expand_path(default_config_path)
      
      
      default_solr_war_path      = File.expand_path(File.join(base_path, "../../../../../../jetty/webapps/solr.war"))
      default_solr_marc_mem_args = '-Xmx512m'      
      default_solr_marc_jar_path = File.expand_path(File.join(base_path, "../../solr_marc/SolrMarc.jar"))

     # Take command line/env args if present, and turn everything into
     # an absolute, rather than relative, file path, so we can do
     # our working directory switching later to keep solrmarc happy. 
      
      solr_marc_jar_path = File.expand_path(ENV['SOLR_MARC_JAR_PATH'] || default_solr_marc_jar_path)
      
      solr_marc_mem_args = (ENV['SOLR_MARC_MEM_ARGS'] || default_solr_marc_mem_args)
      
      solr_war_path = File.expand_path(ENV['SOLR_WAR_PATH'] || default_solr_war_path)

      config_path = File.expand_path(ENV['CONFIG_PATH'] || default_config_path)
      
      marc_records_path = ENV['MARC_FILE']
      marc_records_path = File.expand_path(marc_records_path) if marc_records_path


      task :work do
        # If no marc records given, display :info task
        unless marc_records_path          
          marc_records_path = "[marc records path needed]"
          Rake::Task[ "solr:marc:index:info" ].execute
          exit
        end
      
      
        # if relative path to solr.path and solr.inderxer.properties is given
        # in the config.properties file, solrmarc will consider that relative
        # to the working directory. We want to treat them as relative to
        # to the config.properties file itself instead, so we will
        # change our working directory to the parent of config.properties
        # first. 
        original_wd = Dir.pwd
        Dir.chdir( File.dirname(config_path) )       
        
        commandStr = "java #{solr_marc_mem_args} -Done-jar.class.path=#{solr_war_path} -jar #{solr_marc_jar_path} #{config_path} #{marc_records_path}"
        puts commandStr
        puts
        `#{commandStr}`

        Dir.chdir(original_wd)
        
      end # work
      
      desc "Shows more info about the solr:marc:index task."
      task :info do 
        puts <<-EOS
  Possible environment variables, with specified or default settings:
  
  MARC_FILE: #{marc_records_path}
  
  CONFIG_PATH: #{config_path}
     config default looks first in:
       RAILS_ROOT/config/SolrMarc/config-ENVIRONMENT.properties
     and then in:  RAILS_ROOT/config/SolrMarc/config.properties
     and then in: BLACKLIGHT_PLUGIN/config/SolrMarc/config.properties
  
  SOLR_WAR_PATH: #{solr_war_path}
  
  SOLR_MARC_JAR_PATH: #{solr_marc_jar_path}
  
  SOLR_MARC_MEM_ARGS: #{solr_marc_mem_args}
  
  SolrMarc command that will be run:
  
  java #{solr_marc_mem_args} -Done-jar.class.path=#{solr_war_path} -jar #{solr_marc_jar_path} #{config_path} #{marc_records_path}
  EOS
      end
    end # index
  end # :marc
end # :solr