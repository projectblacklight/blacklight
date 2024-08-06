# frozen_string_literal: true

module Blacklight
  module Assets
    class ImportmapGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.3'), desc: "Set the generated app's bootstrap version"

      # Add css files from blacklight-frontend
      def add_package
        if ENV['CI']
          run "yarn add file:#{Blacklight::Engine.root}"
        else
          run 'yarn add blacklight-frontend'
        end
      end

      # This could be skipped if you want to use webpacker
      def add_javascript_dependencies
        gem 'bootstrap', options[:'bootstrap-version'].presence # in rails 7, only for stylesheets
        gem 'jquery-rails' if bootstrap_4? # Bootstrap 4 has a dependency on jquery
      end

      def import_javascript_assets
        append_to_file 'config/importmap.rb' do
          <<~CONTENT
            pin "@github/auto-complete-element", to: "https://cdn.skypack.dev/@github/auto-complete-element"
            pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.6/dist/umd/popper.min.js"
            pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@#{(defined?(Bootstrap) && Bootstrap::VERSION) || '5.3.2'}/dist/js/bootstrap.js"
          CONTENT
        end

        append_to_file 'app/assets/config/manifest.js' do
          <<~CONTENT
            //= link blacklight/manifest.js
          CONTENT
        end
      end

      def append_blacklight_javascript
        # revert the addition that may already have been done if generated with --css=bootstrap
        gsub_file 'app/javascript/application.js', /import \* as bootstrap from "bootstrap"/, ''
        append_to_file 'app/javascript/application.js' do
          <<~CONTENT
            import bootstrap from "bootstrap"
            import githubAutoCompleteElement from "@github/auto-complete-element"
            import Blacklight from "blacklight"
          CONTENT
        end
      end

      def add_stylesheet
        append_to_file 'app/assets/stylesheets/application.bootstrap.scss' do
          <<~CONTENT
            @import "blacklight-frontend/app/assets/stylesheets/blacklight/blacklight";
          CONTENT
        end
      end

      def bootstrap_4?
        options[:'bootstrap-version'].match?(/\A[^0-9]*4\./)
      end
    end
  end
end
