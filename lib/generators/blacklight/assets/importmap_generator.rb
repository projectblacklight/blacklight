# frozen_string_literal: true

module Blacklight
  module Assets
    class ImportmapGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.3'), desc: "Set the generated app's bootstrap version"

      def add_javascript_dependencies
        gem 'bootstrap', options[:'bootstrap-version'].presence # in rails 7, only for stylesheets
        gem 'jquery-rails' if bootstrap_4? # Bootstrap 4 has a dependency on jquery
      end

      def create_sprockets_manifest_if_needed
        # BL8 still optionally supports Sprockets for CSS, but Rails 8+
        # no longer creates the manifest.js file that Sprockets requires.
        # We don't need to if we already have one, or if we're using
        # cssbundling (which would create an application.bootstrap.scss file)
        # via a `rails new` invocation with `--css bootstrap`.
        return if File.exist?('app/assets/config/manifest.js')
        return if File.exist?('app/assets/stylesheets/application.bootstrap.scss')

        create_file 'app/assets/config/manifest.js' do
          <<~CONTENT
            //= link_tree ../images
            //= link_directory ../stylesheets .css
            //= link_tree ../../javascript .js
          CONTENT
        end
      end

      def import_javascript_assets
        append_to_file 'config/importmap.rb' do
          <<~CONTENT
            pin "@github/auto-complete-element", to: "https://cdn.jsdelivr.net/npm/@github/auto-complete-element@3.8.0/+esm"
            pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.6/dist/umd/popper.min.js"
            pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@#{(defined?(Bootstrap) && Bootstrap::VERSION) || '5.3.2'}/dist/js/bootstrap.js"
          CONTENT
        end

        return unless File.exist?('app/assets/config/manifest.js')

        append_to_file 'app/assets/config/manifest.js' do
          <<~CONTENT
            //= link blacklight/manifest.js
          CONTENT
        end
      end

      def append_blacklight_javascript
        # This may already be present if rails new was invoked with `--css bootstrap'
        append_to_file 'app/javascript/application.js' do
          <<~CONTENT
            import * as bootstrap from "bootstrap"
          CONTENT
        end

        append_to_file 'app/javascript/application.js' do
          <<~CONTENT
            import githubAutoCompleteElement from "@github/auto-complete-element"
            import Blacklight from "blacklight"
          CONTENT
        end
      end

      def add_stylesheet
        if File.exist? 'app/assets/stylesheets/application.bootstrap.scss'
          if ENV['CI']
            run "yarn add file:#{Blacklight::Engine.root}"
          else
            run "yarn add blacklight-frontend@#{Blacklight::VERSION}"
          end

          append_to_file 'app/assets/stylesheets/application.bootstrap.scss' do
            <<~CONTENT
              @import "blacklight-frontend/app/assets/stylesheets/blacklight/blacklight";
            CONTENT
          end
        else
          # NOTE: sassc-rails pulls in sprockets-rails, which requires that a
          # manifest.js file exists.
          gem "sassc-rails", "~> 2.1"

          create_file 'app/assets/stylesheets/blacklight.scss' do
            <<~CONTENT
              @import 'bootstrap';
              @import 'blacklight/blacklight';
            CONTENT
          end

          # application.css in a Rails 8 app has no Sprockets require
          # directives, so blacklight.scss won't be included unless we add one.
          inject_into_file 'app/assets/stylesheets/application.css',
                           "\n *= require blacklight",
                           before: "\n */"
        end
      end

      def bootstrap_4?
        options[:'bootstrap-version'].match?(/\A[^0-9]*4\./)
      end
    end
  end
end
