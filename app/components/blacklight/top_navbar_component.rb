# frozen_string_literal: true

module Blacklight
  class TopNavbarComponent < Blacklight::Component
    def initialize(blacklight_config:)
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config

    delegate :container_classes, to: :helpers
  end
end
