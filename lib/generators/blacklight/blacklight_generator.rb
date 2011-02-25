require 'rails/generators'
require 'rails/generators/migration'     

class BlacklightGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  
  source_root File.expand_path('../templates', __FILE__)
  desc """
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Adds additional mime types to you application in the file '/config/initializers/mime_types.rb'
 3. Creates config/initializers/blacklight_config.rb which you should then modify for your instance
 4. Creates config/solr.yml with a default solr configuration that should work with standard marc records
 6. Creates congig/SolrMarc/... with settings for SolrMarc
 7. Creates user and user_session objects which can be modified and extended, but which currently
    rely on Authlogic. 
 8. Adds the authlogic gem to your Gemfile if it does not exist yet.
 9. Creates a number of public assets, including images, stylesheets, and javascript
10. Adds a solr_marc.jar file to your lib/ directory 
    (where it can be automatically loaded if you are using Jruby)
Thank you for Installing Blacklight.

           """ 
  # Implement the required interface for Rails::Generators::Migration.
  # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
  def self.next_migration_number(path)
    unless @prev_migration_nr
      @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
    else
      @prev_migration_nr += 1
    end
    @prev_migration_nr.to_s
  end

  # Content types used by Marc Document extension, possibly among others.
  # Registering a unique content type with 'register' (rather than
  # register_alias) will allow content-negotiation for the format. 
  def add_mime_types
    puts "Updating Mime Types"
    insert_into_file "config/initializers/mime_types.rb", :after => "# Be sure to restart your server when you modify this file." do <<EOF
Mime::Type.register_alias "text/plain", :refworks_marc_txt
Mime::Type.register_alias "text/plain", :openurl_kev
Mime::Type.register "application/x-endnote-refer", :endnote
Mime::Type.register "application/marc", :marc
Mime::Type.register "application/marcxml+xml", :marcxml, 
      ["application/x-marc+xml", "application/x-marcxml+xml", 
       "application/marc+xml"]
EOF
    end     
  end

  # Copy all files in templates/config directory to host config
  def create_configuration_files
    copy_file "config/blacklight_config.rb", "config/initializers/blacklight_config.rb"
    copy_file "config/solr.yml", "config/solr.yml"
    directory("config/SolrMarc")
  end
  
  # Create user session objects
  def create_user_session_objects
    copy_file "app/user_session.rb", "app/models/user_session.rb"        
    copy_file "app/user.rb", "app/models/user.rb"   
    copy_file "app/users_controller.rb", "app/controller/users_controller.rb"   
  end
  
  # Copy all files in templates/public/ directory to public/
  def copy_public_assets 
    directory("public")
  end
  
  # Setup the database migrations
  def copy_migrations
    begin
      better_migration_template 'migrations/create_users.rb', 'db/migrate/create_users.rb'
      better_migration_template 'migrations/create_searches.rb', 'db/migrate/create_searches.rb'
      better_migration_template 'migrations/create_bookmarks.rb', 'db/migrate/create_bookmarks.rb'
      better_migration_template 'migrations/add_authlogic_fields_to_users.rb', 'db/migrate/add_authlogic_fields_to_users.rb'
      better_migration_template 'migrations/acts_as_taggable_migration.rb', 'db/migrate/acts_as_taggable_migration.rb'
      better_migration_template 'migrations/acts_as_taggable_on_migration.rb', 'db/migrate/acts_as_taggable_on_migration.rb'
    end
  end

  # Add gem files
  def add_gems    
    gem("authlogic")
  end

  # Copy ocver the solr_marc.jar file
  def copy_solr_marc 
    copy_file "SolrMarc.jar", "lib/SolrMarc.jar"
  end

  private  
  
  def better_migration_template (source, dest)
    begin
      migration_template source, dest
      sleep 1 # ensure scripts have different time stamps
    rescue
      p $!.message # rescue the error if the migration already exists, and just tell the user that it exists
    end
  end

end  

