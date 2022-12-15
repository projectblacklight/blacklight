# frozen_string_literal: true

module Blacklight
  module Document
    # Render the sidebar on the show view
    class SidebarComponent < Blacklight::Component
      # @param [Blacklight::DocumentPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @document = presenter.document
      end

      attr_reader :document
    end
  end
end
