# frozen_string_literal: true

module Blacklight
  class Sprockets < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)
    JS_FILE = "app/assets/javascripts/application.js"

    # This could be skipped if you want to use webpacker
    def add_javascript_dependencies
      return unless File.exist?(JS_FILE) # In Rails 6 we use Yarn/Webpacker

      gem 'bootstrap', '~> 4.0'
      gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
      gem 'jquery-rails'
    end

    def assets
      copy_file "blacklight.scss", "app/assets/stylesheets/blacklight.scss"

      # Check that the js file exists.  It doesn't in Rails 6.
      # Also, ensure this method is idempotent
      return if !File.exist?(JS_FILE) || has_blacklight_assets?

      contents = "\n//\n// Required by Blacklight\n"
      contents += "//= require jquery\n"
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

      insert_into_file JS_FILE, after: marker do
        contents
      end
    end

    private

    def file
      @file ||= IO.read(JS_FILE)
    end

    def turbolinks?
      file.include?('turbolinks')
    end

    def has_blacklight_assets?
      file.include?('blacklight/blacklight')
    end
  end
end
