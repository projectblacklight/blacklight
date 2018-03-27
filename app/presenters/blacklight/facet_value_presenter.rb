module Blacklight
  class FacetValuePresenter
    # @param [String] field
    # @param [String, Blacklight::Solr::Response::Facets::FacetItem] raw_value
    # @param [#blacklight_config] view_context
    def initialize(field, raw_value, view_context)
      @field = field
      @view_context = view_context
      @value = if raw_value.respond_to? :label
                 raw_value.label
               elsif raw_value.respond_to? :value
                 raw_value.value
               else
                 raw_value
               end
    end

    attr_reader :field, :value, :view_context

    delegate :facet_configuration_for_field, :l, to: :view_context

    ##
    # Get the displayable version of a facet's value
    #
    # @return [String]
    def display
      facet_config = facet_configuration_for_field(field)

      if facet_config.helper_method
        view_context.send facet_config.helper_method, value
      elsif facet_config.query && facet_config.query[value]
        facet_config.query[value][:label]
      elsif facet_config.date
        localization_options = facet_config.date == true ? {} : facet_config.date

        l(value.to_datetime, localization_options)
      else
        value
      end
    end
  end
end
