# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module Blacklight
  class UserGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    argument     :model_name, type: :string, default: "user"
    class_option :devise, type: :boolean, default: false, aliases: "-d", desc: "Use Devise as authentication logic (this is default)."

    desc <<-EOS
      This generator makes the following changes to your application:
       1. Creates a devise-based user model
       2. Injects blacklight-specific behavior into your user model
    EOS
    # Install Devise?
    def generate_devise_assets
      return unless options[:devise]

      gem "devise"
      gem "devise-guests", "~> 0.8"

      inside destination_root do
        Bundler.with_unbundled_env do
          run "bundle install"
        end
      end

      generate "devise:install"
      generate "devise", model_name.classify
      generate "devise_guests", model_name.classify

      gsub_file("config/initializers/devise.rb", "config.sign_out_via = :delete", "config.sign_out_via = :get")
      # Work around for https://github.com/heartcombo/devise/issues/5720
      gsub_file("config/initializers/devise.rb", "# config.reload_routes = true", "config.reload_routes = false")
    end

    # Add Blacklight to the user model
    def inject_blacklight_user_behavior
      file_path = "app/models/#{model_name.underscore}.rb"
      if File.exist?(File.expand_path(file_path, destination_root))
        inject_into_class file_path, model_name.classify do
          <<~EOS
            # Connects this user object to Blacklights Bookmarks.
            include Blacklight::User

            # Blacklight::User uses a method on your User class to get a user-displayable
            # label (e.g. login or identifier) for the account. Blacklight uses `email' by default.
            # self.string_display_key = :email
          EOS
        end
      else
        say_status "warning", <<~EOS, :yellow
          Blacklight authenticated user functionality not installed, as a user model
          could not be found at #{file_path}. If you used a different name,
          please re-run the migration and provide that name as an argument. E.g.:

            `rails -g blacklight:user client`
        EOS
      end
    end
  end
end
