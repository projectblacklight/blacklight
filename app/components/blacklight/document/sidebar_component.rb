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

      def render_show_tools
        blacklight_config.view_config(:show).show_tools_component&.tap do |show_tools_component_class|
          return render show_tools_component_class.new(document: document)
        end

        render 'show_tools', document: document, silence_deprecation: helpers.partial_from_blacklight?('show_tools')
      end
    end
  end
end
