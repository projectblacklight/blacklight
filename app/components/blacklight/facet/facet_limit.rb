# frozen_string_literal: true

module Blacklight
  module Facet
    class FacetLimit < ActionView::Component::Base
      def initialize(display_facet:, blacklight_config:, response: nil, layout: 'catalog/facet_layout')
        @display_facet = display_facet
        @blacklight_config = blacklight_config
        @response = response
        @layout = layout
      end

      attr_reader :response, :layout

      private

      def field_config
        @field_config ||= facet_configuration_for_field(display_facet.name)
      end

      ##
      # The name of the partial to use to render a facet field.
      # uses the value of the "partial" field if set in the facet configuration
      # otherwise uses "facet_pivot" if this facet is a pivot facet
      # defaults to 'facet_limit'
      #
      # @return [String]
      def facet_partial_name
        config = facet_configuration_for_field(display_facet.name)
        name = config.try(:partial)
        name ||= "catalog/facet_pivot" if config.pivot
        name || "catalog/facet_limit"
      end

      delegate :facet_configuration_for_field, to: :blacklight_config
      attr_reader :blacklight_config, :display_facet
    end
  end
end
