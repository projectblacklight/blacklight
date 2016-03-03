# frozen_string_literal: true
module Blacklight
  class Install < Rails::Generators::Base
    
    source_root File.expand_path('../templates', __FILE__)
    
    argument     :model_name  , type: :string , default: "user"
    argument     :controller_name, type: :string , default: "catalog"
    argument     :document_name, type: :string , default: "solr_document"
    argument     :search_builder_name, type: :string , default: "search_builder"
    argument     :solr_version, type: :string , default: "latest"

    class_option :devise      , type: :boolean, default: false, aliases: "-d", desc: "Use Devise as authentication logic."
    class_option :jettywrapper, type: :boolean, default: false, desc: "Use jettywrapper to download and control Jetty"
    class_option :marc        , type: :boolean, default: false, aliases: "-m", desc: "Generate MARC-based demo ."

    desc """
  This generator makes the following changes to your application:
   1. Generates blacklight:models
   2. Generates utilities for working with solr 
   3. Adds globalid to the Gemfile
   4. Creates a number of public assets, including images, stylesheets, and javascript
   5. Injects behavior into your user application_controller.rb
   6. Adds example configurations for dealing with MARC-like data
   7. Adds Blacklight routes to your ./config/routes.rb

  Thank you for Installing Blacklight.
         """

    def add_solr_wrapper
      if options[:jettywrapper]
        generate 'blacklight:solr4'
      elsif solr_version == 'latest'
        generate 'blacklight:solr5'
      else
        generate "blacklight:solr#{solr_version}"
      end
    end

    def add_globalid_gem
      gem "globalid"
    end

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
    
    def generate_blacklight_document
      generate 'blacklight:document', document_name
    end

    def generate_search_builder
      generate 'blacklight:search_builder', search_builder_name
    end

    def generate_blacklight_models
      generate 'blacklight:models'
    end
    
    def generate_blacklight_user

      generator_args = [model_name]
      if options[:devise]
        generator_args << "--devise #{options[:devise]}"
      end
      
      generate 'blacklight:user', generator_args.join(" ")
    end

    def generate_controller
      generate 'blacklight:controller', controller_name
    end
    
    def add_default_catalog_route
      route("root to: \"#{controller_name}#index\"")
    end

    def add_sass_configuration

      insert_into_file "config/application.rb", :after => "config.assets.enabled = true" do <<EOF

      # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
      config.assets.compress = !Rails.env.development?
EOF
      end
    end

    def inject_blacklight_i18n_strings
      copy_file "blacklight.en.yml", "config/locales/blacklight.en.yml"
    end

    def generate_blacklight_marc_demo
      if options[:marc]
        blacklight_marc = String.new('blacklight-marc')
        gem blacklight_marc, '~> 6.0'

        Bundler.with_clean_env do
          run "bundle install"
        end

        generate 'blacklight:marc:install'
      end
    end

    def add_routes
      route "mount Blacklight::Engine => '/'"
    end
  end
end
