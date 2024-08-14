# frozen_string_literal: true

module Blacklight
  class TopNavbarComponent < Blacklight::Component
    def initialize(blacklight_config:)
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config

    delegate :application_name, :container_classes, to: :helpers

    def aria_label
      t('blacklight.top_navbar.aria.container_label')
    end

    def logo_link(title: application_name)
      link_to title, blacklight_config.logo_link, class: 'mb-0 navbar-brand navbar-logo'
    end
  end
end
