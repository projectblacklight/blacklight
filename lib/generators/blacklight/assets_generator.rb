# frozen_string_literal: true

module Blacklight
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 4.0'), desc: "Set the generated app's bootstrap version"

    # This could be skipped if you want to use webpacker
    def add_javascript_dependencies
      gem 'bootstrap', options[:'bootstrap-version']
      gem 'jquery-rails'
    end

    ##
    # Remove the empty generated app/assets/images directory. Without doing this,
    # the default Sprockets 4 manifest will raise an exception.
    def appease_sprockets4
      return if !defined?(Sprockets::VERSION) || Sprockets::VERSION < '4'

      append_to_file 'app/assets/config/manifest.js', "\n//= link application.js"
      empty_directory 'app/assets/images'
    end

    def assets
      copy_file "blacklight.scss", "app/assets/stylesheets/blacklight.scss"

      # Ensure this method is idempotent
      return if has_blacklight_assets?

      if Rails.version >= '7'
        create_file 'app/assets/javascripts/application.js' do
          <<~CONTENT
            //= require turbo
          CONTENT
        end
      else
        create_file 'app/assets/javascripts/application.js' do
          <<~CONTENT
            //= require turbolinks
            //= require rails-ujs
          CONTENT
        end
      end

      append_to_file 'app/assets/javascripts/application.js' do
        <<~CONTENT
          //= require jquery3

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
