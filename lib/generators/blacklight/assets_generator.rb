# frozen_string_literal: true
module Blacklight
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 4.0'), desc: "Set the generated app's bootstrap version"

    # This could be skipped if you want to use webpacker
    def add_javascript_dependencies
      gem 'bootstrap', options[:'bootstrap-version']
      gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
    end

    def appease_rails7
      return unless Rails.version > '7'

      gem "sassc-rails", "~> 2.1"
    end

    # Add sprockets javascript if needed
    def create_sprockets_javascript
      # Rails 5 already has an application.js file
      return if Rails.version < '6'

      create_file 'app/assets/javascripts/application.js' do
        <<~CONTENT
          //= require jquery3
          //= require rails-ujs
          #{'//= require turbolinks' if Rails.version < '7'}
        CONTENT
      end
    end

    ##
    # Remove the empty generated app/assets/images directory. Without doing this,
    # the default Sprockets 4 manifest will raise an exception.
    def appease_sprockets4
      return if !defined?(Sprockets::VERSION) || Sprockets::VERSION < '4' || using_importmap?

      empty_directory 'app/assets/images'
    end

    def assets
      copy_file "blacklight.scss", "app/assets/stylesheets/blacklight.scss"

      # Ensure this method is idempotent
      return if has_blacklight_assets?

      gem 'jquery-rails'
      contents = "\n//\n// Required by Blacklight\n"
      contents += "//= require popper\n"
      contents += "// Twitter Typeahead for autocomplete\n"
      contents += "//= require twitter/typeahead\n"
      contents += "//= require bootstrap\n"
      contents += "//= require blacklight/blacklight\n"

      marker = if turbolinks?
                 '//= require turbolinks'
               else
                 '//= require rails-ujs'
               end

      insert_into_file "app/assets/javascripts/application.js", after: marker do
        contents
      end

      insert_into_file "app/assets/javascripts/application.js", before: '//= require rails-ujs' do
        "//= require jquery3\n"
      end
    end

    private

    def root
      @root ||= Pathname(destination_root)
    end

    def using_importmap?
      @using_importmap ||= root.join('config/importmap.rb').exist?
    end

    def turbolinks?
      @turbolinks ||= application_js.include?('turbolinks')
    end

    def has_blacklight_assets?
      application_js.include?('blacklight/blacklight')
    end

    def application_js
      path = File.expand_path("app/assets/javascripts/application.js", destination_root)

      File.exist?(path) ? File.read(path) : ''
    end
  end
end
