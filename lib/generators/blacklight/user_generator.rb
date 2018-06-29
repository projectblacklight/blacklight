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
      gem "devise-guests", "~> 0.6"

      Bundler.with_clean_env do
        run "bundle install"
      end

      generate "devise:install"
      generate "devise", model_name.classify
      generate "devise_guests", model_name.classify

      # add the #to_s to the model.
      insert_into_file("app/models/#{model_name}.rb", before: /end(\n| )*$/) do
        "\n  # Method added by Blacklight; Blacklight uses #to_s on your\n" \
        "  # user class to get a user-displayable login/identifier for\n" \
        "  # the account.\n" \
        "  def to_s\n" \
        "    email\n" \
        "  end\n"
      end
      gsub_file("config/initializers/devise.rb", "config.sign_out_via = :delete", "config.sign_out_via = :get")
    end

    # Add Blacklight to the user model
    def inject_blacklight_user_behavior
      file_path = "app/models/#{model_name.underscore}.rb"
      if File.exist?(file_path)
        inject_into_class file_path, model_name.classify do
          "\n  # Connects this user object to Blacklights Bookmarks." \
          "\n  include Blacklight::User\n"
        end
      else
        say_status "warning", <<-EOS.strip_heredoc, :yellow
          Blacklight authenticated user functionality not installed, as a user model
          could not be found at /app/models/user.rb. If you used a different name,
          please re-run the migration and provide that name as an argument. E.g.:

            `rails -g blacklight:user client`
        EOS
      end
    end
  end
end
