# frozen_string_literal: true

module Blacklight
  class HeaderComponent < Blacklight::Component
    renders_one :top_bar, lambda { |component: Blacklight::TopNavbarComponent|
      component.new(blacklight_config: blacklight_config)
    }

    renders_one :search_bar, lambda { |component: Blacklight::SearchNavbarComponent|
      component.new(blacklight_config: blacklight_config)
    }

    def initialize(blacklight_config:)
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config

    # Hack so that the default lambdas are triggered
    # so that we don't have to do c.with_top_bar() in the call.
    def before_render
      set_slot(:top_bar, nil) unless top_bar
      set_slot(:search_bar, nil) unless search_bar
    end
  end
end
