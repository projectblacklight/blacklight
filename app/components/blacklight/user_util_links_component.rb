# frozen_string_literal: true

module Blacklight
  class UserUtilLinksComponent < Blacklight::Component

    renders_many :nav_actions

    def initialize(blacklight_config:, display_account_links: false)
      @blacklight_config = blacklight_config
      @display_account_links = display_account_links
    end

    attr_accessor :blacklight_config

    delegate :current_user, :blacklight_configuration_context, to: :helpers

    def display_account_links?
      @display_account_links
    end

    def tools
      partials = blacklight_config.navbar.partials
      partials.select { |_, config| blacklight_configuration_context.evaluate_if_unless_configuration config, {} }.values
    end
  end
end
