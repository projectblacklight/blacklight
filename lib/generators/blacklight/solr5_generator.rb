require 'rails/generators'

module Blacklight
  class Solr5Generator < Rails::Generators::Base

    # Set source_root to grab .solr_wrapper and solr config dir
    # from the root of the blacklight gem
    source_root Blacklight.root

    desc <<-EOF
      This generator makes the following changes to your application:
       1. Installs solr_wrapper into your application
       2. Copies default blacklight solr config directory into your application
       3. Copies default .solr_wrapper into your application
       4. Adds rsolr to your Gemfile
    EOF

    def install_solrwrapper
      gem_group :development, :test do
        gem 'solr_wrapper', '>= 0.3'
      end

      append_to_file "Rakefile", "\nrequire 'solr_wrapper/rake_task' unless Rails.env.production?\n"
    end

    def copy_solr_conf
      directory 'solr', 'solr'
    end

    def solr_wrapper_config
      copy_file '.solr_wrapper.yml', '.solr_wrapper.yml'
    end

    def add_rsolr_gem
      gem 'rsolr', '~> 1.0'
    end
  end
end
