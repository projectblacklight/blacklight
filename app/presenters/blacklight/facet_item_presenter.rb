# frozen_string_literal: true

module Blacklight
  class FacetItemPresenter
    attr_reader :facet_item, :facet_config, :view_context, :search_state, :facet_field

    delegate :hits, :items, to: :facet_item

    def initialize(facet_item, facet_config, view_context, facet_field, search_state = view_context.search_state)
      @facet_item = facet_item
      @facet_config = facet_config
      @view_context = view_context
      @facet_field = facet_field
      @search_state = search_state
    end

    ##
    # Check if the query parameters have the given facet field with the
    # given value.
    def selected?
      Deprecation.silence(Blacklight::SearchState) do
        search_state.has_facet? facet_config, value: facet_value
      end
    end

    def field_label
      facet_field_presenter.label
    end

    ##
    # Get the displayable version of a facet's value
    #
    # @return [String]
    def label
      return @view_context.facet_display_value(@facet_field, @facet_item) unless @view_context.method(:facet_display_value).owner == Blacklight::FacetsHelperBehavior

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

    def href(path_options = {})
      if selected?
        remove_href
      else
        add_href(path_options)
      end
    end

    # @private
    def remove_href(path = search_state)
      Deprecation.silence(Blacklight::SearchState) do
        view_context.search_action_path(path.remove_facet_params(facet_config.key, facet_item))
      end
    end

    # @private
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

    def facet_field_presenter
      @facet_field_presenter ||= view_context.facet_field_presenter(facet_config, {})
    end
  end
end
