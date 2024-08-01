# frozen_string_literal: true

module Blacklight
  module Assets
    class ImportmapGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.3'), desc: "Set the generated app's bootstrap version"

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

        # NOTE: manifest may not exist if they installed with "-a propshaft"
        return unless File.exist?('app/assets/config/manifest.js')

        append_to_file 'app/assets/config/manifest.js' do
          <<~CONTENT
            //= link blacklight/manifest.js
          CONTENT
        end
      end

      def append_blacklight_javascript
        # NOTE: Avoid reimport of bootstrap (if they ran --css=bootstrap)
        # see https://github.com/rails/cssbundling-rails/blob/4f4c62148bbee215a4694d6970be30f17c3066dd/lib/install/bootstrap/install.rb#L17-L20
        append_to_file "app/javascript/application.js", %(import * as bootstrap from "bootstrap"\n)
        append_to_file 'app/javascript/application.js' do
          <<~CONTENT
            import githubAutoCompleteElement from "@github/auto-complete-element"
            import Blacklight from "blacklight"
          CONTENT
        end
      end

      def add_stylesheet
        # NOTE: this indicates they installed with --css=bootstrap
        if File.exist?('app/assets/stylesheets/application.bootstrap.scss')
          append_to_file 'app/assets/stylesheets/application.bootstrap.scss' do
            <<~CONTENT
              @import "blacklight-frontend/app/assets/stylesheets/blacklight/blacklight";
            CONTENT
          end
        else
          gem "sassc-rails", "~> 2.1" if Rails.version > '7'

          create_file 'app/assets/stylesheets/blacklight.scss' do
            <<~CONTENT
              @import 'bootstrap';
              @import 'blacklight/blacklight';
            CONTENT
          end
        end
      end

      def bootstrap_4?
        options[:'bootstrap-version'].match?(/\A[^0-9]*4\./)
      end
    end
  end
end
