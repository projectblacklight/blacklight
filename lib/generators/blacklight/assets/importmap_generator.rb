# frozen_string_literal: true

module Blacklight
  module Assets
    class ImportmapGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.3'), desc: "Set the generated app's bootstrap version"

      # Add css files from blacklight-frontend
      def add_package
        if ENV['CI']
          run "yarn add blacklight-frontend:#{Blacklight::Engine.root}"
        else
          run 'yarn add blacklight-frontend'
        end
      end

      # This could be skipped if you want to use webpacker
      def add_javascript_dependencies
        gem 'bootstrap', options[:'bootstrap-version'].presence # in rails 7, only for stylesheets
      end

      def import_javascript_assets
        append_to_file 'config/importmap.rb' do
          <<~CONTENT
            pin "@github/auto-complete-element", to: "https://cdn.skypack.dev/@github/auto-complete-element"
            pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.6/dist/umd/popper.min.js"
            pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@#{(defined?(Bootstrap) && Bootstrap::VERSION) || '5.3.2'}/dist/js/bootstrap.js"
          CONTENT
        end

        return unless defined?(Sprockets)

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
          gem "sassc-rails", "~> 2.1"

          create_file 'app/assets/stylesheets/blacklight.scss' do
            <<~CONTENT
              @import 'bootstrap';
              @import 'blacklight/blacklight';
            CONTENT
          end
        end
      end
    end
  end
end
