# frozen_string_literal: true

module Blacklight
  module Document
    # Render the tools that display on the sidebar of the show page
    class ShowToolsComponent < Blacklight::Component
      # @param [Blacklight::Document] document
      def initialize(document:)
        @document = document
      end

      attr_reader :document

      def render?
        helpers.show_doc_actions?
      end

      def actions
        helpers.document_actions(document)
      end
    end
  end
end
