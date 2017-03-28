# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module Blacklight
  class ModelsGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    desc <<-EOS
    This generator makes the following changes to your application:
     1. Creates several database migrations if they do not exist in /db/migrate
     2. Creates config/blacklight.yml with a default configuration
    EOS

    # Copy all files in templates/config directory to host config
    def create_configuration_files
      copy_file "config/blacklight.yml", "config/blacklight.yml"
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

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end
      EOF
    end
  end
end
