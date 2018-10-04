# frozen_string_literal: true
module Blacklight
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    # This could be skipped if you want to use webpacker
    def add_javascript_dependencies
      gem 'bootstrap', '~> 4.0'
      gem 'popper_js'
      gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
    end

    def assets
      copy_file "blacklight.scss", "app/assets/stylesheets/blacklight.scss"

      # Ensure this method is idempotent
      return if has_blacklight_assets?

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

      insert_into_file "app/assets/javascripts/application.js", after: marker do
        contents
      end
    end

    # This is not a default in Rails 5.1+
    def add_jquery
      gem 'jquery-rails'
    end

    private

    def turbolinks?
      @turbolinks ||= IO.read("app/assets/javascripts/application.js").include?('turbolinks')
    end

    def has_blacklight_assets?
      IO.read("app/assets/javascripts/application.js").include?('blacklight/blacklight')
    end
  end
end
