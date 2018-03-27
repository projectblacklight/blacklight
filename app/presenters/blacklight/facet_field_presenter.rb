# frozen_string_literal: true

module Blacklight
  class FacetFieldPresenter
    include Blacklight::Facet
    class_attribute :facet_item_presenter
    self.facet_item_presenter = FacetItemPresenter

    # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
    def initialize(display_facet, view_context)
      @display_facet = display_facet
      @view_context = view_context
    end

    delegate :blacklight_config, :content_tag, :safe_join, :render, to: :@view_context
    attr_reader :display_facet, :view_context

    def as_json
      { 'name' => display_facet.name,
        'items' => json_items }

    end

    ##
    # Renders the list of values
    # removes any elements where render_facet_item returns a nil value. This enables an application
    # to filter undesireable facet items so they don't appear in the UI
    def render_facet_limit_list(paginator, facet_field, wrapping_element = :li)
      safe_join(paginator.items.map { |item| facet_item_presenter.new(facet_field, item, view_context).render_item }.compact.map { |item| content_tag(wrapping_element, item) })
    end

    ##
    # Determine if Blacklight should render the display_facet or not
    #
    # By default, only render facets with items.
    #
    # @return [Boolean]
    def render?
      # display when show is nil or true
      # rubocop:disable Rails/Blank
      return false unless present?
      # rubocop:enable Rails/Blank
      view_context.should_render_field?(facet_config, display_facet)
    end

    def facet_config
      facet_configuration_for_field(display_facet.name)
    end

    def present?
      display_facet.items.present?
    end

    ##
    # Renders a single section for facet limit with a specified
    # solr field used for faceting. Can be over-ridden for custom
    # display on a per-facet basis.
    #
    # @param [Hash] options parameters to use for rendering the facet limit partial
    # @option options [String] :partial partial to render
    # @option options [String] :layout partial layout to render
    # @option options [Hash] :locals locals to pass to the partial
    # @return [String]
    def render_facet_limit(options = {})
      return unless render?
      options = options.dup
      options[:partial] ||= partial_name
      options[:layout] ||= "facet_layout" unless options.key?(:layout)
      options[:locals] ||= {}
      options[:locals][:field_name] ||= display_facet.name
      options[:locals][:facet_field] ||= facet_config
      options[:locals][:display_facet] ||= display_facet
      options[:locals][:presenter] = self

      render(options)
    end

    private

    def json_items
      display_facet.items.map do |item|
        facet_item_presenter.new(display_facet, item, view_context).as_json
      end
    end

    ##
    # The name of the partial to use to render a facet field.
    # uses the value of the "partial" field if set in the facet configuration
    # otherwise uses "facet_pivot" if this facet is a pivot facet
    # defaults to 'facet_limit'
    #
    # @return [String]
    def partial_name
      config = facet_config
      name = config.try(:partial)
      name ||= "facet_pivot" if config.pivot
      name || "facet_limit"
    end
  end
end
