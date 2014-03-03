require 'rails/generators'
require 'rails/generators/migration'

module Blacklight
  class ModelsGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    argument     :model_name, :type => :string , :default => "user"
    class_option :devise    , :type => :boolean, :default => false, :aliases => "-d", :desc => "Use Devise as authentication logic (this is default)."

    desc """
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Creates config/solr.yml with a default solr configuration
 3. Injects behavior into your user model
 4. Creates a blacklight document in your /app/models directory
"""

    def check_arguments
      if File.exists?("app/models/#{model_name}.rb") and options[:devise]
        puts "Because you have selected \"#{model_name}\", which is an existing class, you will need to install devise manually and then run this generator without the Devise option.  You can find additional information here: https://github.com/plataformatec/devise.  \n Please be sure to include a to_s method in #{model_name} that returns the users name or email, as this will be used by Blacklight to provide a link to user specific information."
        exit
      end
    end

    # Install Devise?
    def generate_devise_assets
      if options[:devise]
        gem "devise"
        gem "devise-guests", "~> 0.3"

        Bundler.with_clean_env do
          run "bundle install"
        end

        generate "devise:install"
        generate "devise", model_name.classify
        generate "devise_guests", model_name.classify

        # add the #to_s to the model.
        insert_into_file("app/models/#{model_name}.rb", :before => /end(\n| )*$/) do
          %{
            # Method added by Blacklight; Blacklight uses #to_s on your
            # user class to get a user-displayable login/identifier for
            # the account.
            def to_s
              email
            end
          }
        end
        gsub_file("config/initializers/devise.rb", "config.sign_out_via = :delete", "config.sign_out_via = :get")
      end
    end

    # Copy all files in templates/config directory to host config
    def create_configuration_files
      copy_file "config/solr.yml", "config/solr.yml"
    end


    # Setup the database migrations
    def copy_migrations
      rake "blacklight:install:migrations"
    end


    # Add Blacklight to the user model
    def inject_blacklight_user_behavior
      file_path = "app/models/#{model_name.underscore}.rb"
      if File.exists?(file_path)
        inject_into_class file_path, model_name.classify do
          "\n  attr_accessible :email, :password, :password_confirmation if Rails::VERSION::MAJOR < 4\n" +
            "# Connects this user object to Blacklights Bookmarks. " +
            "\n  include Blacklight::User\n"
        end
      else
        say_status("warning", "Blacklight authenticated user functionality not installed, as a user model could not be found at /app/models/user.rb. If you used a different name, please re-run the migration and provide that name as an argument. Such as `rails -g blacklight client`", :yellow)
      end
    end

    def create_solr_document
      copy_file "solr_document.rb", "app/models/solr_document.rb"
    end

  end
end
