module Blacklight
  class FacetListPresenter
    include Blacklight::Facet

    class_attribute :field_presenter
    self.field_presenter = FacetFieldPresenter

    def initialize(response, view_context)
      @response = response
      @view_context = view_context
    end

    delegate :blacklight_config, :content_tag, :safe_join, to: :@view_context
    attr_reader :view_context

    ##
    # Check if any of the given fields have values
    #
    # @param [Array<String>] fields
    # @return [Boolean]
    def values? fields = facet_field_names
      presenters_for_request(fields).any?(&:render?)
    end

    ##
    # Render a collection of facet fields.
    #
    # @param [Array<String>] fields
    # @param [Hash] options
    # @return String
    def render_partials fields = facet_field_names, options = {}
      safe_join(presenters_for_request(fields).map do |presenter|
        presenter.render_facet_limit(options)
      end.compact, "\n")
    end

    # @param [Array<String>] fields
    # @return [Hash]
    def as_json(fields = facet_field_names)
      presenters_for_request(fields).map(&:as_json)
    end

    private

    def presenters_for_request(fields)
      facets_from_request(fields).map do |display_facet|
        field_presenter.new(display_facet, view_context)
      end
    end

    def facets_from_request(fields = facet_field_names)
      fields.map { |field| facet_by_field_name(field) }.compact
    end
  end
end
