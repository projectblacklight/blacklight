# frozen_string_literal: true

module Blacklight
  module Facets
    # Display count of a facet value
    class CountComponent < Blacklight::Component
      def initialize(hits:, classes:)
        @hits = hits
        @classes = classes
      end

      attr_reader :hits, :classes

      def render?
        hits.present?
      end

      def call
        tag.span(t('blacklight.search.facets.count', number: number_with_delimiter(hits)), class: classes)
      end
    end
  end
end
