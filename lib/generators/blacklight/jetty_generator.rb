# -*- encoding : utf-8 -*-
require 'openssl'

module Blacklight
  class Jetty < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    
    argument :save_location, :type=>"string", :desc => "where to install the jetty", :default => "./jetty"
    class_option :environment, :aliases => "-e", :type=>"string", :desc => "environment to use jetty with. Will insert into solr.yml, and also offer to index test data in test environment.", :default => Rails.env
    # change this to a different download if you want to peg to a different
    # tagged version of our known-good jetty/solr.
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE # (Required by jruby)
    class_option :download_url, :aliases => "-u", :type=>"string", :default =>"https://github.com/projectblacklight/blacklight-jetty/zipball/v4.0.0" , :desc=>"location of zip file including a jetty with solr setup for blacklight."
    class_option :downloaded_package, :aliases => "-d", :type=>"string", :desc => "manual download of BL-jetty zip file"
     
    
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
        unless options[:downloaded_package]
          begin        
            say_status("fetching", options[:download_url])
            zip_file = File.join(tmp_save_dir, "bl_jetty.zip")                
            get(options[:download_url], zip_file)
          rescue Exception => e
            say_status("error", "Could not download #{options[:download_url]} : #{e}", :red)
            raise Thor::Error.new("Try downloading manually and then using '-d' option?")
          end
        else
          zip_file = options[:downloaded_package]
        end
        
        
        say_status("unzipping", zip_file)
        "unzip -d #{tmp_save_dir} -qo #{zip_file}".tap do |command|          
          system(command) or raise Thor::Error.new("Error executing: #{command}")       
        end        
        # It unzips into a top_level directory we've got to find by name
        # in the tmp dir, sadly. 
        expanded_dir = Dir[File.join(tmp_save_dir, "projectblacklight-blacklight-jetty-*")].first        

        if File.exists?( save_location ) && ! options[:force]
          raise Thor::Error.new("cancelled by user") unless [nil, "", "Y", "y"].include? ask("Copy over existing #{save_location}? [Yn]")
        end
        
        directory(expanded_dir, save_location, :verbose => false)
        say_status("installed", save_location )
      ensure
        remove_dir(tmp_save_dir)
      end                  
    end
   
    
  end
end
