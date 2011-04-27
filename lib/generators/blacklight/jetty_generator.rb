
module Blacklight
  class Jetty < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    
    # change this to a different download if you want to peg to a different
    # tagged version of our known-good jetty/solr. 
    class_option :download_url, :aliases => "-u", :type=>"string", :default =>"https://github.com/projectblacklight/blacklight-jetty/zipball/v1.4.1-1" , :desc=>"location of zip file including a jetty with solr setup for blacklight."
    class_option :save_location, :aliases => "-o", :type=>"string", :desc => "where to install the jetty", :default => "./jetty"
    class_option :environment, :aliases => "-e", :type=>"string", :desc => "environment to use jetty with. Will insert into solr.yml, and also offer to index test data in test environment.", :default => Rails.env 
    
    desc """ 
Installs a jetty container with a solr installed in it. A solr setup known 
good with default blacklight setup, including solr conf files for out
of the box blacklight. 

Also adds jetty_path key to solr.yml for selected environment, to refer
to this install. 

Requires system('unzip... ') to work, probably won't work on Windows.

"""
    
    def download_jetty         
      tmp_save_dir = File.join(Rails.root, "tmp", "jetty_generator")      
      empty_directory(tmp_save_dir)
      
      begin
        say_status("fetching", options[:download_url])
        zip_file = File.join(tmp_save_dir, "bl_jetty.zip")                
        get(options[:download_url], zip_file)
      
        
        say_status("unzipping", zip_file)
        "unzip -d #{tmp_save_dir} -qo #{zip_file}".tap do |command|          
          system(command) or raise Thor::Error.new("Error executing: #{command}")       
        end        
        # It unzips into a top_level directory we've got to find by name
        # in the tmp dir, sadly. 
        expanded_dir = Dir[File.join(tmp_save_dir, "projectblacklight-blacklight-jetty-*")].first        

        if File.exists?(options[:save_location]) && ! options[:force]
          raise Thor::Error.new("cancelled by user") unless [nil, "", "Y", "y"].include? ask("Copy over existing #{options[:save_location]}? [Yn]")
        end
        
        directory(expanded_dir, options[:save_location], :verbose => false)
        say_status("installed", options[:save_location])
      ensure
        remove_dir(tmp_save_dir)
      end                  
    end
    
    # the only thing that's REALLY BL-specific is these conf files
    # installed by another generator. We write em on top of the solr we
    # just installed. We "force" it because we're usually writing on top of files
    # we just installed anyway. The user should have said 'no' to overwriting
    # their dir if they already had one!  
    #
    # If we later install Solr from somewhere other than BL jetty repo, we'd
    # still want to write these on top, just like this. 
    def install_conf_files
      generate("blacklight:solr_conf", "#{File.join(options[:save_location], 'solr', 'conf')} --force")
    end
    
    # adds a jetty_path key to solr.yml for the current environment, so
    # rake tasks for automatically starting jetty/solr (as well as
    # for indexing with solrmarc) can find it. 
    def add_jetty_path_to_solr_yml        
      # inject_into_file no-ops silently if the :after isn't found, we
      # want to be noisy. 
      config_file = "config/solr.yml"
      config_file_full_path = File.expand_path(config_file, destination_root)
      after_hook = /#{Regexp.escape(options[:environment])}\:[^\n]*\n/
            
      if !(File.exists?(config_file_full_path) && File.binread( config_file_full_path ) =~ after_hook)
        say_status("skipped", "Could not find '#{options[:environment]}' block in #{config_file} to add jetty_path to.", :red)
      elsif File.binread( config_file_full_path  ) =~ /#{Regexp.escape(options[:environment])}\:[^\n]*\n.*(?!\n\n).*jetty_path\:/
        say_status("skipped", "#{config_file} '#{options[:environment]}' block already has jetty_path, not overwriting.", :red)        
      else
        inject_into_file config_file, :verbose => false, :after => after_hook do
          "  jetty_path: '#{options[:save_location]}'\n"
        end
        say_status("insert", "#{config_file}: jetty_path key for '#{options[:environment]}' block")
      end                    
    end
    
    
  end
end
