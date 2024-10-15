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
        return generate_with_sassc_rails unless used_bootstrap_css?

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
      end

      private

      # Did they generate the rails app with `--css bootstrap' ?
      def used_bootstrap_css?
        File.exist? 'app/assets/stylesheets/application.bootstrap.scss'
      end

      def generate_with_sassc_rails
        gem "sassc-rails", "~> 2.1"
        # This could be skipped if you want to use shakapacker or cssbunding-rails
        gem 'bootstrap', options[:'bootstrap-version'].presence

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
