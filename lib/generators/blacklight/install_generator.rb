# frozen_string_literal: true
module Blacklight
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument     :model_name, type: :string, default: "user"
    argument     :controller_name, type: :string, default: "catalog"
    argument     :document_name, type: :string, default: "solr_document"
    argument     :search_builder_name, type: :string, default: "search_builder"

    class_option :devise, type: :boolean, default: false, aliases: "-d", desc: "Use Devise as authentication logic."
    class_option :marc, type: :boolean, default: false, aliases: "-m", desc: "Generate MARC-based demo."
    class_option :'bootstrap-version', type: :string, default: nil, desc: "Set the generated app's bootstrap version"
    class_option :'skip-assets', type: :boolean, default: !defined?(Sprockets), desc: "Skip generating javascript and css assets into the application"
    class_option :'skip-solr', type: :boolean, default: false, desc: "Skip generating solr configurations."

    desc <<-EOS
      This generator makes the following changes to your application:
       1. Generates blacklight:models
       2. Generates utilities for working with solr
       3. Creates a number of public assets, including images, stylesheets, and javascript
       4. Injects behavior into your user application_controller.rb
       5. Adds example configurations for dealing with MARC-like data
       6. Adds Blacklight routes to your ./config/routes.rb

      Thank you for Installing Blacklight.
    EOS

    def add_solr_wrapper
      generate 'blacklight:solr' unless options[:'skip-solr']
    end

    # Copy all files in templates/public/ directory to public/
    # Call external generator in AssetsGenerator, so we can
    # leave that callable seperately too.
    def copy_public_assets
      generated_options = "--bootstrap-version #{options[:'bootstrap-version']}" if options[:'bootstrap-version']

      generate "blacklight:assets", generated_options unless options[:'skip-assets']
    end

    def bundle_install
      inside destination_root do
        Bundler.with_clean_env do
          run "bundle install"
        end
      end
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

    def inject_blacklight_i18n_strings
      copy_file "blacklight.en.yml", "config/locales/blacklight.en.yml"
    end

    def generate_blacklight_marc_demo
      return unless options[:marc]

      blacklight_marc = String.new('blacklight-marc')
      gem blacklight_marc, '>= 7.0.0.rc1', '< 8'

      bundle_install

      generate 'blacklight:marc:install'
    end

    def add_routes
      route "mount Blacklight::Engine => '/'"
    end
  end
end
