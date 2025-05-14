# frozen_string_literal: true

module Blacklight
  module Facets
    class SuggestComponent < Blacklight::Component
      def initialize(presenter:)
        @presenter = presenter
      end

      private

      attr_accessor :presenter

      delegate :suggest, :key, :label, to: :presenter

      def render?
        # Draw if suggest is true or not present
        suggest != false
      end
    end
  end
end
