# frozen_string_literal: true

module Blacklight
  module Search
    class FacetSuggestInput < Blacklight::Component
      def initialize(facet:, presenter:)
        @facet = facet
        @presenter = presenter
      end

      private

      attr_accessor :facet, :presenter
    end
  end
end
