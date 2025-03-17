# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'
require 'blacklight/version'

module Blacklight
  class ModelsGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    desc <<-EOS
    This generator makes the following changes to your application:
     1. Creates several database migrations if they do not exist in /db/migrate
    EOS

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
