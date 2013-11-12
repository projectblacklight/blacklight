# -*- encoding : utf-8 -*-
require 'rails/generators'

class BlacklightGenerator < Rails::Generators::Base

  source_root File.expand_path('../templates', __FILE__)
  
  argument     :model_name, :type => :string , :default => "user"
  class_option :devise    , :type => :boolean, :default => false, :aliases => "-d", :desc => "Use Devise as authentication logic (this is default)."
  
  desc """
This generator makes the following changes to your application:
 1. Generates blacklight:models
 2. Creates a number of public assets, including images, stylesheets, and javascript
 3. Injects behavior into your user application_controller.rb
 4. Adds example configurations for dealing with MARC-like data
 5. Adds Blacklight routes to your ./config/routes.rb


Thank you for Installing Blacklight.
       """ 

  def bundle_install
    Bundler.with_clean_env do
      run "bundle install"
    end
  end

  # Copy all files in templates/public/ directory to public/
  # Call external generator in AssetsGenerator, so we can
  # leave that callable seperately too. 
  def copy_public_assets 
    generate "blacklight:assets"
  end

  def generate_blacklight_models

    generator_args = []
    if options[:devise]
      generator_args << "--devise #{options[:devise]}"
    end
    
    generate 'blacklight:models', generator_args.join(" ")
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
  
  # TODO
  # def generate_stub_catalog_controller
  ## see blacklight:marc generator
  ##copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
  #end 

  def generate_blacklight_marc_demo
    generate 'blacklight:marc'
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

end  

