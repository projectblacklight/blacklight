# frozen_string_literal: true

require 'rails/generators'

module Blacklight
  class SolrGenerator < Rails::Generators::Base
    source_root ::File.expand_path('../templates', __FILE__)

    desc <<-EOF
      This generator makes the following changes to your application:
       1. Creates config/blacklight.yml
       2. Installs solr_wrapper into your application
       3. Copies default blacklight solr config directory into your application
       4. Copies default .solr_wrapper into your application
       5. Adds rsolr to your Gemfile
    EOF

    # Copy all files in templates/config directory to host config
    def create_configuration_file
      copy_file "config/blacklight_solr.yml", "config/blacklight.yml"
      gsub_file 'config/blacklight.yml', '__VERSION__', Blacklight::VERSION
    end

    def install_solrwrapper
      gem_group :development, :test do
        gem 'solr_wrapper', '>= 0.3'
      end

      append_to_file "Rakefile", "\nrequire 'solr_wrapper/rake_task' unless Rails.env.production?\n"
    end

    def copy_solr_conf
      raise "XXXXXX"
      directory 'solr'
    end

    def solr_wrapper_config
      copy_file '.solr_wrapper.yml'
    end

    def add_rsolr_gem
      gem 'rsolr', '>= 1.0', '< 3'
    end

    def bundle_install
      inside destination_root do
        Bundler.with_unbundled_env do
          run "bundle install"
        end
      end
    end
  end
end
