# frozen_string_literal: true

require 'rails/generators'

module Blacklight
  class ElasticsearchGenerator < Rails::Generators::Base
    source_root ::File.expand_path('templates', __dir__)

    desc <<-EOF
      This generator makes the following changes to your application:
      1. Adds elasticsearch to your Gemfile
      1. Adds config/blacklight.yml
    EOF

    # Copy all files in templates/config directory to host config
    def create_configuration_file
      copy_file "config/blacklight_elasticsearch.yml", "config/blacklight.yml"
      gsub_file 'config/blacklight.yml', '__VERSION__', Blacklight::VERSION
    end

    def configure_catalog
      gsub_file 'app/controllers/catalog_controller.rb', /# config\.repository_class.*/,
                'config.repository_class = Blacklight::Elasticsearch::Repository'
      gsub_file 'app/controllers/catalog_controller.rb', /# config\.response_model.*/,
                'config.response_model = Blacklight::Elasticsearch::Response'
    end

    def add_rsolr_gem
      gem 'elasticsearch', '~> 8.17'
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
