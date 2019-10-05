# frozen_string_literal: true

module Blacklight
  module Facet
    class Group < ActionView::Component::Base
      include Blacklight::Facet # for facet_field_names

      def initialize(groupname:, response:, blacklight_config:)
        @groupname = groupname
        @response = response
        @blacklight_config = blacklight_config
      end

      attr_reader :response

      ##
      # Check if any of the given fields have values
      #
      # @param [Array<String>] fields
      # @return [Boolean]
      def has_facet_values?
        facets_from_request.any? { |display_facet| should_render_facet?(display_facet) }
      end

      def facet_names
        facet_field_names(groupname)
      end

      private

      ##
      # Determine if Blacklight should render the display_facet or not
      #
      # By default, only render facets with items.
      #
      # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
      # @return [Boolean]
      def should_render_facet? display_facet
        return false if display_facet.items.blank?

        # display when show is nil or true
        facet_config = facet_configuration_for_field(display_facet.name)
        should_render_field?(facet_config, display_facet)
      end

      ##
      # Determine whether to render a field by evaluating :if and :unless conditions
      #
      # @param [Blacklight::Solr::Configuration::Field] field_config
      # @return [Boolean]
      def should_render_field?(field_config, display_facet)
        blacklight_configuration_context.evaluate_if_unless_configuration field_config, display_facet
      end

      def blacklight_configuration_context
        @blacklight_configuration_context ||= Blacklight::Configuration::Context.new(controller)
      end

      # @param fields [Array<String>] a list of facet field names
      # @return [Array<Solr::Response::Facets::FacetField>]
      def facets_from_request
        facet_names.map { |field| facet_by_field_name(field) }.compact
      end

      # Get a FacetField object from the response
      def facet_by_field_name(field_name)
        facet_field = facet_configuration_for_field(field_name)
        response.aggregations[facet_field.field]
      end

      delegate :facet_configuration_for_field, to: :blacklight_config
      attr_reader :groupname, :blacklight_config
    end
  end
end
