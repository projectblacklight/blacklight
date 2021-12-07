# frozen_string_literal: true
module ControllerLevelHelpers
  module ControllerViewHelpers
    include Blacklight::Facet

    def search_state
      @search_state ||= Blacklight::SearchState.new(params, blacklight_config, controller)
    end

    def blacklight_configuration_context
      @blacklight_configuration_context ||= Blacklight::Configuration::Context.new(controller)
    end
  end

  def initialize_controller_helpers(helper)
    helper.extend ControllerViewHelpers
  end

  # Monkeypatch to fix https://github.com/rspec/rspec-rails/pull/2521
  def _default_render_options
    val = super
    return val unless val[:handlers]

    val.merge(handlers: val.fetch(:handlers).map(&:to_sym))
  end
end
