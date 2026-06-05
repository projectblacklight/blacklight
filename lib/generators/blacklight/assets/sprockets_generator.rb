# frozen_string_literal: true

module Blacklight
  module Assets
    class SprocketsGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 4.0'), desc: "Set the generated app's bootstrap version"

      def replace_propshaft_with_sprockets
        return if defined?(Sprockets)

        # Rails 8+ defaults to Propshaft, but Blacklight 7.x JS requires Sprockets
        gsub_file 'Gemfile', /^gem ['"]propshaft['"].*$/, '# \0'
        gem 'sprockets-rails'
      end

      def add_javascript_dependencies
        gem 'bootstrap', options[:'bootstrap-version'].presence
        gem 'jquery-rails'
        gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
      end

      def add_sass_support
        gem "sassc-rails", "~> 2.1" if Rails.version > '7'
      end

      def setup_sprockets_manifest
        if !defined?(Sprockets)
          # Rails 8+ with Propshaft replaced: create Sprockets config from scratch
          directory = File.expand_path('app/assets/config', destination_root)
          FileUtils.mkdir_p(directory)
          create_file 'app/assets/config/manifest.js' do
            <<~CONTENT
              //= link_tree ../images
              //= link_directory ../stylesheets .css
              //= link application.js
            CONTENT
          end
          empty_directory 'app/assets/images'
        elsif defined?(Sprockets::VERSION) && Sprockets::VERSION >= '4'
          append_to_file 'app/assets/config/manifest.js', "\n//= link application.js"
          empty_directory 'app/assets/images'
        end
      end

      def assets
        create_file 'app/assets/stylesheets/blacklight.scss' do
          <<~CONTENT
            @import 'bootstrap';
            @import 'blacklight/blacklight';
          CONTENT
        end

        # Ensure application.css is a proper Sprockets manifest that loads blacklight styles
        application_css = File.expand_path('app/assets/stylesheets/application.css', destination_root)
        if File.exist?(application_css)
          content = File.read(application_css)
          unless content.include?('require blacklight')
            create_file 'app/assets/stylesheets/application.css', force: true do
              <<~CONTENT
                /*
                 *= require blacklight
                 *= require_self
                 */
              CONTENT
            end
          end
        end

        # Ensure this method is idempotent
        return if has_blacklight_assets?

        create_file 'app/assets/javascripts/application.js' do
          <<~CONTENT
            //= require jquery3
            //= require rails-ujs

            // Required by Blacklight
            //= require popper
            // Twitter Typeahead for autocomplete
            //= require twitter/typeahead
            //= require bootstrap
            //= require blacklight/blacklight
          CONTENT
        end
      end

      private

      def has_blacklight_assets?
        application_js.include?('blacklight/blacklight')
      end

      def application_js
        path = File.expand_path("app/assets/javascripts/application.js", destination_root)

        File.exist?(path) ? File.read(path) : ''
      end
    end
  end
end
