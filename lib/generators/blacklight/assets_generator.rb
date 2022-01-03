# frozen_string_literal: true

module Blacklight
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 4.0'), desc: "Set the generated app's bootstrap version"

    # This could be skipped if you want to use webpacker
    def add_javascript_dependencies
      gem 'bootstrap', options[:'bootstrap-version'] # in rails 7, only for stylesheets
    end

    ##
    # Remove the empty generated app/assets/images directory. Without doing this,
    # the default Sprockets 4 manifest will raise an exception.
    # def appease_sprockets4
    #   return if !defined?(Sprockets::VERSION) || Sprockets::VERSION < '4'
    #
    #   append_to_file 'app/assets/config/manifest.js', "\n//= link application.js"
    #   empty_directory 'app/assets/images'
    # end

    def assets # rubocop:disable Metrics/MethodLength
      copy_file "blacklight.scss", "app/assets/stylesheets/blacklight.scss"

      # Ensure this method is idempotent
      return if has_blacklight_assets?

      if Rails.version > '7'
        gem "sassc-rails", "~> 2.1"
        append_to_file 'config/importmap.rb' do
          <<~CONTENT
            pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.1.3/dist/js/bootstrap.js"
            pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.0/lib/index.js"
            pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.6.0/dist/jquery.js"
          CONTENT
        end

        append_to_file 'app/javascripts/application.js' do
          <<~CONTENT
            import "jquery"
            import bootstrap from "bootstrap"
            window.bootstrap = bootstrap // Required for Blacklight 7 so it can manage the modals
          CONTENT
        end
      else
        gem 'jquery-rails'
        create_file 'app/assets/javascripts/application.js' do
          <<~CONTENT
            //= require turbolinks
            //= require rails-ujs
            //= require jquery3

            // Required by Blacklight
            //= require popper
            //= require bootstrap
            //= require blacklight/blacklight
          CONTENT
        end
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
