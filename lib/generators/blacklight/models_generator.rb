# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'
require 'blacklight/version'

module Blacklight
  class ModelsGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('templates', __dir__)

    desc <<-EOS
    This generator makes the following changes to your application:
     1. Creates several database migrations if they do not exist in /db/migrate
     2. Creates config/blacklight.yml with a default configuration
    EOS

    # Copy the connection configuration to the host's config directory. The
    # adapter is resolved at generation time from the BLACKLIGHT_ADAPTER
    # environment variable (defaulting to Solr), so the generated
    # config/blacklight.yml is static and the choice does not need to be
    # re-supplied on every boot.
    def create_configuration_files
      source = if ENV['BLACKLIGHT_ADAPTER'].to_s =~ /elastic|opensearch/
                 "config/blacklight.elasticsearch.yml"
               else
                 "config/blacklight.yml"
               end

      copy_file source, "config/blacklight.yml"
      gsub_file 'config/blacklight.yml', '__VERSION__', Blacklight::VERSION
    end

    # Setup the database migrations
    def copy_migrations
      rake "blacklight:install:migrations"
    end

    def add_routes
      route <<-EOF

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks, only: [:index, :update, :create, :destroy] do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end
      EOF
    end
  end
end
