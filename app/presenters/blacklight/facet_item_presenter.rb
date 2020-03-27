module Blacklight
  class FacetItemPresenter
    attr_reader :facet_item, :facet_config, :view_context, :configuration, :search_state

    def initialize(facet_item, facet_config, view_context, configuration = view_context.blacklight_config, search_state = view_context.search_state)
      @facet_item = facet_item
      @facet_config = facet_config
      @view_context = view_context
      @configuration = configuration
      @search_state = search_state
    end

    ##
    # Check if the query parameters have the given facet field with the
    # given value.
    def selected
      search_state.has_facet? facet_config, value: facet_value
    end

    ##
    # Get the displayable version of a facet's value
    #
    # @param [Object] field
    # @param [String] item value
    # @return [String]
    def label
      value = if facet_item.respond_to? :label
                facet_item.label
              else
                facet_value
              end

      if facet_config.helper_method
        view_context.public_send(facet_config.helper_method, value)
      elsif facet_config.query && facet_config.query[value]
        facet_config.query[value][:label]
      elsif facet_config.date
        localization_options = facet_config.date == true ? {} : facet_config.date
        I18n.l(Time.zone.parse(value), localization_options)
      else
        value
      end
    end

    def hits
      facet_item.hits
    end

    def href(path_options = {})
      if selected
        remove_href
      else
        add_href(path_options)
      end
    end

    def remove_href
      view_context.search_action_path(search_state.remove_facet_params(facet_config.key, facet_item))
    end

    def add_href(path_options = {})
      if facet_config.url_method
        view_context.public_send(facet_config.url_method, facet_config.key, facet_item)
      else
        view_context.search_action_path(search_state.add_facet_params_and_redirect(facet_config.key, facet_item).merge(path_options))
      end
    end

    private

    def facet_value
      if facet_item.respond_to? :value
        facet_item.value
      else
        facet_item
      end
    end
  end
end
