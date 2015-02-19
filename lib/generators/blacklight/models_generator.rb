require 'rails/generators'
require 'rails/generators/migration'

module Blacklight
  class ModelsGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    desc """
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Creates config/blacklight.yml with a default configuration
"""
    # Copy all files in templates/config directory to host config
    def create_configuration_files
      copy_file "config/blacklight.yml", "config/blacklight.yml"
    end


    # Setup the database migrations
    def copy_migrations
      rake "blacklight:install:migrations"
    end


  end
end
