# frozen_string_literal: true

module Blacklight
  module Assets
    class ImportmapGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.1'), desc: "Set the generated app's bootstrap version"

      # This could be skipped if you want to use webpacker
      def add_javascript_dependencies
        gem 'bootstrap', options[:'bootstrap-version'].presence # in rails 7, only for stylesheets
        gem 'jquery-rails' if bootstrap_4? # Bootstrap 4 has a dependency on jquery
      end

      def import_javascript_assets
        append_to_file 'config/importmap.rb' do
          <<~CONTENT
            pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.6/dist/umd/popper.min.js"
            pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@#{(defined?(Bootstrap) && Bootstrap::VERSION) || '5.2.2'}/dist/js/bootstrap.js"
            pin "blacklight", to: "blacklight/blacklight.js"
          CONTENT
        end
      end

      def append_blacklight_javascript
        append_to_file 'app/javascript/application.js' do
          <<~CONTENT
            import bootstrap from "bootstrap"
            import "blacklight"
          CONTENT
        end
      end

      def add_stylesheet
        gem "sassc-rails", "~> 2.1" if Rails.version > '7'

        create_file 'app/assets/stylesheets/blacklight.scss' do
          <<~CONTENT
            @import 'bootstrap';
            @import 'blacklight/blacklight';
          CONTENT
        end
      end

      def bootstrap_4?
        options[:'bootstrap-version'].match?(/\A[^0-9]*4\./)
      end
    end
  end
end
