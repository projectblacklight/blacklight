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

    # Add sprockets javascript to Rails 6.
    def create_sprockets_javascript
      return if Rails.version < '6.0.0'

      create_file 'app/assets/javascripts/application.js' do
        <<~CONTENT
          //= require jquery3
          //= require rails-ujs
          //= require turbolinks
        CONTENT
      end
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

    # This is not a default in Rails 5.1+
    def add_jquery
      gem 'jquery-rails'
    end

    private

    def turbolinks?
      @turbolinks ||= application_js.include?('turbolinks')
    end

    def has_blacklight_assets?
      application_js.include?('blacklight/blacklight')
    end

    def application_js
      IO.read(File.expand_path("app/assets/javascripts/application.js", destination_root))
    end
  end
end
