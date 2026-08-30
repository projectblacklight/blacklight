# frozen_string_literal: true

module Blacklight
  class IndexPresenter < DocumentPresenter
    def view_config
      @view_config ||= blacklight_config_presenter.view_config
    end

    def blacklight_config_presenter
      @blacklight_config_presenter ||= configuration.configuration_presenter_class.new(configuration, view_context: view_context)
    end
  end
end
