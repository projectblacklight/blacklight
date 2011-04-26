# -*- coding: undecided -*-
# Rake tasks for the SolrMarc Java indexer.
# Marc Record defaults to indexing lc_records.utf8.mrc
# config.properties defaults to config/demo_config.properties (in the plugin, not the rails app)


require 'fileutils'



namespace :solr do
  namespace :marc do
    
    
    desc "Index the supplied test data into Solr"
    task :index_test_data do
      # for now we are assuming test data is located in BL source checkout. 
      ENV['MARC_FILE'] = File.expand_path("./test_support/data/test_data.utf8.mrc", Blacklight.root )
      # and just for now, temporary thing as I continue to work on Rails3 migration,
      # assume that the jetty/solr install we want to write to is in the
      # BL source checkout too, and point there, forcing the issue. 
      ENV['SOLR_WAR_PATH'] = File.expand_path("./test_support/jetty/webapps/solr.war", Blacklight.root)
      ENV['SOLR_PATH'] = File.expand_path("./test_support/jetty/solr", Blacklight.root)
      
      Rake::Task[ "solr:marc:index:work" ].invoke
    end
    
    desc "Index marc data using SolrMarc. Available environment variables: MARC_RECORDS_PATH, CONFIG_PATH, SOLR_MARC_MEM_ARGS"
    task :index => "index:work"

    namespace :index do

      task :work do
        solrmarc_arguments = compute_arguments        

        # If no marc records given, display :info task
        if  (ENV["NOOP"] || (!solrmarc_arguments["MARC_FILE"]))                    
          Rake::Task[ "solr:marc:index:info" ].execute
        else        
          commandStr = solrmarc_command_line( solrmarc_arguments )
          puts commandStr
          puts
          `#{commandStr}`
        end
        
      end # work
      
      desc "Shows more info about the solr:marc:index task."
      task :info do
        solrmarc_arguments = compute_arguments
        puts <<-EOS
  Solr to write to is taken from current environment in config/solr.yml, 
  key :replicate_master_url is supported, taking precedence over :url
  for where to write to. 
   
  Possible environment variables, with settings as invoked. You can set these
  variables on the command line, eg:
        rake solr:marc:index MARC_FILE=/some/file.mrc
  
  MARC_FILE: #{solrmarc_arguments["MARC_FILE"] || "[marc records path needed]"}
  
  CONFIG_PATH: #{solrmarc_arguments[:config_properties_path]}
     Defaults to RAILS_ROOT/config/SolrMarc/config(-RAILS_ENV).properties
     or else RAILS_ROOT/vendor/plugins/blacklight/SolrMarc/config ...

     Note that SolrMarc search path includes directory of config_path,
     so translation_maps and index_scripts dirs will be found there. 
  
  SOLRMARC_JAR_PATH: #{solrmarc_arguments[:solrmarc_jar_path]}
  
  SOLRMARC_MEM_ARGS: #{solrmarc_arguments[:solrmarc_mem_arg]}
  
  SolrMarc command that will be run:
  
  #{solrmarc_command_line(solrmarc_arguments)}
  EOS
      end
    end # index
  end # :marc
end # :solr

# Computes arguments to Solr, returns hash
# Calculate default args based on location of rake file itself,
# which we assume to be in the plugin, or in the Rails executing
# this rake task, at RAILS_ROOT. 
def compute_arguments
  
  arguments  = {}

  arguments["MARC_FILE"] = ENV["MARC_FILE"]

  
  app_site_path = File.expand_path(File.join(Rails.root, "config", "SolrMarc"))
  plugin_site_path = File.expand_path(File.join(Rails.root, "vendor", "plugins", "blacklight", "config", "SolrMarc"))


  # Find config in local app or plugin, possibly based on our RAILS_ENV (::Rails.env)
  arguments[:config_properties_path] = ENV['CONFIG_PATH']
  unless arguments[:config_properties_path]
    [ File.join(app_site_path, "config-#{::Rails.env}.properties"  ),
      File.join( app_site_path, "config.properties"),
      File.join( plugin_site_path, "config-#{::Rails.env}.properties"),
      File.join( plugin_site_path, "config.properties"),
    ].each do |file_path|
      if File.exists?(file_path)
        arguments[:config_properties_path] = file_path
        break
      end
    end
  end
  
  #java mem arg is from env, or default

  arguments[:solrmarc_mem_arg] = ENV['SOLRMARC_MEM_ARGS'] || '-Xmx512m'
      
  # SolrMarc is embedded in the plugin, or could be a custom
  # one in local app.  
  arguments[:solrmarc_jar_path] = ENV['SOLRMARC_JAR_PATH'] || locate_path("lib", "SolrMarc.jar") 
  

      

  # Solr URL, find from solr.yml, app or plugin
  # use :replicate_master_url for current env if present, otherwise :url
  # for current env. 
  solr_yml_path = locate_path("config", "solr.yml")
  if ( File.exists?( solr_yml_path ))
    solr_config = YAML::load(File.open(solr_yml_path))
    arguments[:solr_url] = solr_config[ ::Rails.env ]['url'] if solr_config[::Rails.env]
  end
  
  # solrmarc.solr.war.path and solr.path, for now pull out of ENV
  # if present. In progress. jrochkind 25 Apr 2011. 
  arguments[:solr_war_path] = ENV["SOLR_WAR_PATH"] if ENV["SOLR_WAR_PATH"]
  arguments[:solr_path] = ENV['SOLR_PATH'] if ENV['SOLR_PATH']


  return arguments
end

def solrmarc_command_line(arguments)
  cmd = "java #{arguments[:solrmarc_mem_arg]} "
  cmd += " -Dsolr.hosturl=#{arguments[:solr_url]} " unless arguments[:solr_url].blank?
  
  cmd += " -Dsolrmarc.solr.war.path=#{arguments[:solr_war_path]}" unless arguments[:solr_war_path].blank?
  cmd += " -Dsolr.path=#{arguments[:solr_path]}" unless arguments[:solr_path].blank?
  
  cmd += " -jar #{arguments[:solrmarc_jar_path]} #{arguments[:config_properties_path]} #{arguments["MARC_FILE"]}"  
  return cmd  
end


def locate_path(*subpath_fragments)
  local_root = File.expand_path File.join(File.dirname(__FILE__), '..', '..')
  puts "The local_root is #{local_root}"
  subpath = subpath_fragments.join('/')
  base_match = [Rails.root, local_root].find do |base|
    File.exists? File.join(base, subpath)
  end
  File.join(base_match.to_s, subpath) if base_match
end


