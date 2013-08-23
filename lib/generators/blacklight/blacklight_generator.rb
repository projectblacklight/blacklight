# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'     

class BlacklightGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)
  
  argument     :model_name, :type => :string , :default => "user"
  class_option :devise    , :type => :boolean, :default => false, :aliases => "-d", :desc => "Use Devise as authentication logic (this is default)."
  
  desc """
This generator makes the following changes to your application:
 1. Generates blacklight:models
 2. Adds additional mime types to you application in the file '/config/initializers/mime_types.rb'
 3. Creates a number of public assets, including images, stylesheets, and javascript
 4. Adds a solr_marc.jar file to your lib/ directory 
 5. Injects behavior into your user application_controller.rb
 6. Creates a blacklight catalog controller in your /app/controllers directory
 7. Adds Blacklight routes to your ./config/routes.rb
 8. Enables internationalization.

Thank you for Installing Blacklight.
       """ 

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

  def add_unicode_gem
    gem "unicode", :platforms => [:mri_18, :mri_19] unless defined?(:RUBY_VERSION) and RUBY_VERSION == '2.0.0'
  end

  # Copy all files in templates/public/ directory to public/
  # Call external generator in AssetsGenerator, so we can
  # leave that callable seperately too. 
  def copy_public_assets 
    generate "blacklight:assets"
  end

  def generate_blacklight_models
    if options[:devise]
      generate 'blacklight:models', "--devise #{options[:devise]}"
    else
      generate 'blacklight:models'
    end
  end

  # Add Blacklight to the application controller
  def inject_blacklight_controller_behavior    
#    prepend_file("app/controllers/application_controller.rb", "require 'blacklight/controller'\n\n")
    inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
      "  # Adds a few additional behaviors into the application controller \n " +        
        "  include Blacklight::Controller\n" + 
        "  # Please be sure to impelement current_user and user_session. Blacklight depends on \n" +
        "  # these methods in order to perform user specific actions. \n\n" +
        "  layout 'blacklight'\n\n"
    end
  end
  
  # Generate blacklight catalog controller
  def create_blacklight_catalog
    copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
  end

  def inject_blacklight_routes
    # These will end up in routes.rb file in reverse order
    # we add em, since each is added at the top of file. 
    # we want "root" to be FIRST for optimal url generation. 
    route('Blacklight.add_routes(self)')
    route('root :to => "catalog#index"')
  end

  def add_sass_configuration

    insert_into_file "config/application.rb", :after => "config.assets.enabled = true" do <<EOF
    
    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
    config.assets.compress = !Rails.env.development?

EOF
      end

  end

  def add_bootstrap_gem
    # Don't need a version here, because we specify the version in blacklight.gemspec
    gem 'bootstrap-sass'
  end 

end  

