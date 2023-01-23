# frozen_string_literal: true

module Blacklight
  class ShowPresenter < DocumentPresenter
    private

    def field_presenter_options
      { context: 'show' }
    end
  end
end
