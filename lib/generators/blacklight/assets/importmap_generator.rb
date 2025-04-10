# frozen_string_literal: true

module Blacklight
  module Assets
    class ImportmapGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.3'), desc: "Set the generated app's bootstrap version"

      def import_javascript_assets
        append_to_file 'config/importmap.rb' do
          <<~CONTENT
            pin "@github/auto-complete-element", to: "https://cdn.skypack.dev/@github/auto-complete-element"
            pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.6/dist/umd/popper.min.js"
            pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@#{(defined?(Bootstrap) && Bootstrap::VERSION) || '5.3.5'}/dist/js/bootstrap.js"
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
              @import url(https://cdn.jsdelivr.net/npm/bootstrap@5.3.5/dist/css/bootstrap.min.css);
              @import url("blacklight.css");
            CONTENT
          end
        end
      end
    end
  end
end
