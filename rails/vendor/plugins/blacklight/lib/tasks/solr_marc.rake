# Rake tasks for the SolrMarc Java indexer.
# Marc Record defaults to indexing lc_records.utf8.mrc
# config.properties defaults to config/demo_config.properties (in the plugin, not the rails app)


require 'fileutils'

namespace :solr do
  namespace :marc do
    desc "Index marc data using SolrMarc. Available environment variables: SOLR_WAR_PATH, MARC_RECORDS_PATH, SOLR_MARC_MEM_ARGS"
    task :index => "index:work"

    namespace :index do

      base_path = File.dirname(__FILE__)
      bl_config_dir =  File.join(base_path, "../../config")
      default_solr_war_path      = File.join(base_path, "../../../../../../jetty/webapps/solr.war")
      default_marc_records_path  = File.join(base_path, "../../../../../../data/lc_records.utf8.mrc")
      default_solr_marc_mem_args = '-Xmx512m'
      default_config_path = File.join(base_path, "../../config/demo_config.properties")
      solr_marc_jar_path = File.join(base_path, "../../solr_marc/SolrMarc.jar")
      
      solr_marc_mem_args = (ENV['SOLR_MARC_MEM_ARGS'] or default_solr_marc_mem_args)
      solr_war_path = "-Done-jar.class.path=" + (ENV['SOLR_WAR_PATH'] or default_solr_war_path)

      config_path = (ENV['CONFIG_PATH'] or default_config_path)
      marc_records_path = (ENV['MARC_RECORDS_PATH'] or default_marc_records_path)


      task :work do
        # unless full path to solr.indexer.properties is given, copy to working dir
        # as SolrMarc needs it in the jar, working dir, or from a full path
        lines = File.readlines(config_path)
        solr_indexer_properties = lines.find{|line| line =~ /^solr\.indexer\.properties.*$/}.split('=').last.strip
        unless solr_indexer_properties =~ /^\//
          FileUtils.rm_f(solr_indexer_properties)
          FileUtils.cp(File.join(bl_config_dir, solr_indexer_properties), solr_indexer_properties)
        end
        `java #{solr_marc_mem_args} #{solr_war_path} -jar #{solr_marc_jar_path} #{config_path} #{marc_records_path}`
        FileUtils.rm_f(solr_indexer_properties)
      end # work
      
      desc "Shows more info about the solr:marc:index task."
      task :info do 
        puts "Unless solr.indexer.properties has a full path, it will be copied to this dir."
        puts "Defaults for the the possible environment variables are:"
        puts "MARC_RECORDS_PATH: #{default_marc_records_path}"
        puts ""
        puts "CONFIG_PATH: #{default_config_path}"
        puts ""
        puts "SOLR_WAR_PATH: #{default_solr_war_path}"
        puts ""
        puts "SOLR_MARC_MEM_ARGS: #{default_solr_marc_mem_args}"
      end
    end # index
  end # :marc
end # :solr