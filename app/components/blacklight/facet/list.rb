# frozen_string_literal: true

module Blacklight
  module Facet
    class List < ActionView::Component::Base
      def initialize(blacklight_config:, response:)
        @blacklight_config = blacklight_config
        @response = response
      end

      def facet_group_names
        blacklight_config.facet_fields.map { |_facet, opts| opts[:group] }.uniq
      end

      attr_reader :response

      private

      attr_reader :blacklight_config
    end
  end
end
