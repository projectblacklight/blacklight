# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module Blacklight
  class UserGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('templates', __dir__)

    argument     :model_name, type: :string, default: "user"
    class_option :devise, type: :boolean, default: false, aliases: "-d", desc: "Use Devise as authentication logic."
    class_option :authentication, type: :boolean, default: false, desc: "Use Rails' built-in authentication generator."

    desc <<-EOS
      This generator makes the following changes to your application:
       1. Optionally creates an authenticated user model
       2. Injects blacklight-specific behavior into your user model
    EOS

    def validate_authentication_options
      raise Thor::Error, "Choose either --devise or --authentication, not both." if options[:devise] && options[:authentication]
    end

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

    # Install Rails' built-in authentication generator?
    def generate_rails_authentication_assets
      return unless options[:authentication]

      raise Thor::Error, "Rails' authentication generator is only available in Rails 8.0 and newer." unless rails_authentication_generator_available?
      raise Thor::Error, "Rails' authentication generator creates a User model; omit the model name when using --authentication." unless model_name.underscore == "user"

      generate "authentication", rails_authentication_generator_args
      inject_rails_authentication_blacklight_behavior
      inject_rails_authentication_guest_transfer
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
            # label (e.g. login or identifier) for the account.
            #{blacklight_user_display_key_configuration}
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

    private

    def rails_authentication_generator_available?
      Rails.gem_version >= Gem::Version.new("8.0.0")
    end

    def rails_authentication_generator_args
      Rails.application.config.api_only ? "--api" : ""
    end

    def inject_rails_authentication_blacklight_behavior
      inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
        [
          "  # Makes Rails' generated authentication available through Blacklight's auth hooks.",
          "  helper_method :current_user",
          "",
          "  def current_user",
          "    resume_session&.user",
          "  end",
          ""
        ].join("\n")
      end
    end

    # Move bookmarks/searches accumulated by the anonymous guest user over to the
    # real account when they sign in.
    def inject_rails_authentication_guest_transfer
      sessions_path = "app/controllers/sessions_controller.rb"
      return unless File.exist?(File.expand_path(sessions_path, destination_root))

      inject_into_file sessions_path, after: "      start_new_session_for user\n" do
        "      transfer_guest_to_user\n"
      end
    end

    def blacklight_user_display_key_configuration
      if options[:authentication]
        "self.string_display_key = :email_address"
      else
        "# self.string_display_key = :email"
      end
    end
  end
end
