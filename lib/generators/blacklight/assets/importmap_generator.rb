# frozen_string_literal: true

module Blacklight
  module Assets
    class ImportmapGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '5.3.8'), desc: "Set the generated app's bootstrap version"

      def import_javascript_assets
        append_to_file 'config/importmap.rb' do
          <<~CONTENT
            pin "@github/auto-complete-element", to: "https://cdn.jsdelivr.net/npm/@github/auto-complete-element@3.8.0/+esm"
            pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.6/dist/umd/popper.min.js"
            pin "bootstrap", to: "#{bootstrap_javascript_url}"
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
            import Blacklight from "blacklight-frontend"
          CONTENT
        end
      end

      def add_stylesheet
        if File.exist? 'app/assets/stylesheets/application.bootstrap.scss'
          append_to_file 'app/assets/stylesheets/application.bootstrap.scss' do
            <<~CONTENT
              @import url("blacklight.css");
            CONTENT
          end
        else
          append_to_file 'app/assets/stylesheets/application.css' do
            <<~CONTENT
              @import url(https://cdn.jsdelivr.net/npm/bootstrap@#{bootstrap_version}/dist/css/bootstrap.min.css);
              @import url("blacklight.css");
            CONTENT
          end
        end
      end

      private

      def bootstrap_version
        options[:'bootstrap-version']
      end

      def bootstrap_6?
        bootstrap_version.start_with?('6.')
      end

      def bootstrap_javascript_url
        return "https://cdn.jsdelivr.net/npm/bootstrap@#{bootstrap_version}/dist/js/bootstrap.bundle.min.js" if bootstrap_6?

        "https://ga.jspm.io/npm:bootstrap@#{bootstrap_version}/dist/js/bootstrap.js"
      end
    end
  end
end
