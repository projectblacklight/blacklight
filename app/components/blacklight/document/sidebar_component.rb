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

      delegate :blacklight_config, to: :helpers

      private

      def show_tools_component_class
        blacklight_config.view_config(:show).show_tools_component
      end

      def render_show_tools
        render show_tools_component_class.new(document: document)
      end
    end
  end
end
