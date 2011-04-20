require 'rails/generators'
require 'rails/generators/migration'     

class BlacklightGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)
  
  argument     :model_name, :type => :string , :default => "user"
  class_option :devise    , :type => :boolean, :default => false, :aliases => "-d", :desc => "Use Devise as authentication logic (this is default)."
  
  desc """
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Adds additional mime types to you application in the file '/config/initializers/mime_types.rb'
 3. Creates config/initializers/blacklight_config.rb which you should then modify for your instance
 4. Creates config/solr.yml with a default solr configuration that should work with standard marc records
 5. Creates congig/SolrMarc/... with settings for SolrMarc
 6. Creates a number of public assets, including images, stylesheets, and javascript
 7. Adds a solr_marc.jar file to your lib/ directory 
 9. Injects behavior into your user application_controller.rb
 9. Injects behavior into your user model
10. Creates a blacklight catalog controller in your /app/controllers directory
11. Creates a blacklight document in your /app/models directory
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

  # Install Devise? 
  def generate_devise_assets
    if options[:devise]
      gem "devise"
      run "bundle install"      
      generate "devise:install"
      generate "devise", model_name.classify
      generate "devise:views"
    end
  end

  # Copy all files in templates/config directory to host config
  def create_configuration_files
    copy_file "config/blacklight_config.rb", "config/initializers/blacklight_config.rb"
    copy_file "config/solr.yml", "config/solr.yml"
    directory("config/SolrMarc")
  end
  
  # Copy all files in templates/public/ directory to public/
  def copy_public_assets 
    directory("public")
  end
  
  # Setup the database migrations
  def copy_migrations
    # Can't get this any more DRY, because we need this order.
    better_migration_template "create_searches.rb"
    better_migration_template "create_bookmarks.rb"
    better_migration_template "remove_editable_fields_from_bookmarks.rb"
    better_migration_template "add_user_types_to_bookmarks_searches.rb"
  end

  # Copy ocver the solr_marc.jar file
  def copy_solr_marc 
    copy_file "SolrMarc.jar", "lib/SolrMarc.jar"
  end

  # Add Blacklight to the user model
  def inject_blacklight_user_behavior
    file_path = "app/models/#{model_name.underscore}.rb"
    if File.exists?(file_path) 
      inject_into_class file_path, model_name.classify do 
        "# Connects this user object to Blacklights Bookmarks and Folders. " +
        "\n include Blacklight::User\n"        
      end
    else
      puts "     \e[31mFailure\e[0m  Blacklight requires a user object in order to presist bookmarks and saved searches. This generators assumes that the model is defined in the file /app/models/user.rb, which does not exist.  If you used a different name, please re-run the migration and provide that name as an argument. Such as \b  rails -g blacklight client" 
    end    
  end

  # Add Blacklight to the application controller
  def inject_blacklight_controller_behavior    
#    prepend_file("app/controllers/application_controller.rb", "require 'blacklight/controller'\n\n")
    inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
      "  # Adds a few additional behaviors into the application controller \n " +        
        "  include Blacklight::Controller\n" + 
        "  # Please be sure to impelement current_user and user_session. Blacklight depends on \n" +
        "  # these methods in order to perform user specific actions. \n\n"
    end
  end
  
  # Generate blacklight document and the catalog controller
  def create_blacklight_catalog_and_document
    copy_file "solr_document.rb", "app/models/solr_document.rb"
    copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
  end

  private  
  
  def better_migration_template (file)
    begin
      migration_template "migrations/#{file}", "db/migrate/#{file}"
      sleep 1 # ensure scripts have different time stamps
    rescue
      puts "  \e[1m\e[34mMigrations\e[0m  " + $!.message
    end
  end

end  

