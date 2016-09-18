module Blacklight
  class FacetListPresenter
    include Blacklight::Facet

    def initialize(response, view_context)
      @response = response
      @view_context = view_context
    end

    delegate :blacklight_config, :content_tag, :render, :safe_join, to: :@view_context
    attr_reader :view_context

    ##
    # Renders the list of values 
    # removes any elements where render_facet_item returns a nil value. This enables an application
    # to filter undesireable facet items so they don't appear in the UI
    def render_facet_limit_list(paginator, facet_field, wrapping_element = :li)
      safe_join(paginator.items.map { |item| FacetItemPresenter.new(facet_field, item, view_context).render_item }.compact.map { |item| content_tag(wrapping_element, item) })
    end

    ##
    # Check if any of the given fields have values
    #
    # @param [Array<String>] fields
    # @return [Boolean]
    def values? fields = facet_field_names
      facets_from_request(fields).any? { |display_facet| !display_facet.items.empty? && render?(display_facet) }
    end

    ##
    # Determine if Blacklight should render the display_facet or not
    #
    # By default, only render facets with items.
    #
    # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
    # @return [Boolean] 
    def render? display_facet
      # display when show is nil or true
      facet_config = facet_configuration_for_field(display_facet.name)
      display = view_context.should_render_field?(facet_config, display_facet)
      display && display_facet.items.present?
    end

    ##
    # Render a collection of facet fields.
    # @see #render_facet_limit 
    # 
    # @param [Array<String>] fields
    # @param [Hash] options
    # @return String
    def render_partials fields = facet_field_names, options = {}
      view_context.safe_join(facets_from_request(fields).map do |display_facet|
        render_facet_limit(display_facet, options)
      end.compact, "\n")
    end

    ##
    # Renders a single section for facet limit with a specified
    # solr field used for faceting. Can be over-ridden for custom
    # display on a per-facet basis. 
    #
    # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet 
    # @param [Hash] options parameters to use for rendering the facet limit partial
    # @option options [String] :partial partial to render
    # @option options [String] :layout partial layout to render
    # @option options [Hash] :locals locals to pass to the partial
    # @return [String] 
    def render_facet_limit(display_facet, options = {})
      return unless render?(display_facet)
      options = options.dup
      options[:partial] ||= partial_name(display_facet)
      options[:layout] ||= "facet_layout" unless options.key?(:layout)
      options[:locals] ||= {}
      options[:locals][:field_name] ||= display_facet.name
      options[:locals][:facet_field] ||= facet_configuration_for_field(display_facet.name)
      options[:locals][:display_facet] ||= display_facet 
      options[:locals][:presenter] = self 

      render(options)
    end

    private

      ##
      # The name of the partial to use to render a facet field.
      # uses the value of the "partial" field if set in the facet configuration
      # otherwise uses "facet_pivot" if this facet is a pivot facet 
      # defaults to 'facet_limit'
      #
      # @return [String]
      def partial_name(display_facet = nil)
        config = facet_configuration_for_field(display_facet.name)
        name = config.try(:partial)
        name ||= "facet_pivot" if config.pivot
        name || "facet_limit"
      end
  end
end
