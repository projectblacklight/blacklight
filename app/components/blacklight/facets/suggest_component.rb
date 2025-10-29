# frozen_string_literal: true

module Blacklight
  module Facets
    class SuggestComponent < Blacklight::Component
      def initialize(presenter:)
        @presenter = presenter
      end

      private

      attr_accessor :presenter

      delegate :key, :label, to: :presenter

      def render?
        presenter.suggest?
      end
    end
  end
end
