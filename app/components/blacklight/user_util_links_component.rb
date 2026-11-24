# frozen_string_literal: true

module Blacklight
  # Renders the navigation actions (e.g. bookmarks, history), the login/logout
  # links, and the theme switcher in the top navbar.
  class UserUtilLinksComponent < Blacklight::Component
    def initialize(blacklight_config:)
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config

    delegate :render_nav_actions, :has_user_authentication_provider?,
             :blacklight_logout_path, :blacklight_logout_link_options,
             :blacklight_account_path, :blacklight_login_path, to: :helpers

    def dark_mode_support?
      blacklight_config.dark_mode_support
    end

    def current_user
      helpers.current_user if helpers.respond_to?(:current_user)
    end
  end
end
