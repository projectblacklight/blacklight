# frozen_string_literal: true

module Blacklight
  module Assets
    class SprocketsGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.3'), desc: "Set the generated app's bootstrap version"

      # This could be skipped if you want to use webpacker
      def add_javascript_dependencies
        gem 'bootstrap', options[:'bootstrap-version'].presence
      end

      ##
      # Remove the empty generated app/assets/images directory. Without doing this,
      # the default Sprockets 4 manifest will raise an exception.
      def appease_sprockets4
        append_to_file 'app/assets/config/manifest.js', "\n//= link application.js"
        append_to_file 'app/assets/config/manifest.js', "\n//= link blacklight/manifest.js"
        empty_directory 'app/assets/images'
      end

      def assets
        create_file 'app/assets/stylesheets/blacklight.scss' do
          <<~CONTENT
            @import 'bootstrap';
            @import 'blacklight/blacklight';
          CONTENT
        end

        gem "sassc-rails", "~> 2.1"

        # Ensure this method is idempotent
        return if has_blacklight_assets?

        create_file 'app/assets/javascripts/application.js' do
          <<~CONTENT
            //= require rails-ujs

            // Required by Blacklight
            //= require popper
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
