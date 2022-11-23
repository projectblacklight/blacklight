# frozen_string_literal: true

module Blacklight
  class FacetItemPresenter
    attr_reader :facet_item, :facet_config, :view_context, :search_state

    delegate :key, to: :facet_config

    def initialize(facet_item, facet_config, view_context, _facet_field, search_state = view_context.search_state)
      @facet_item = facet_item
      @facet_config = facet_config
      @view_context = view_context
      # @facet_field = facet_field
      @search_state = search_state
    end

    def hits
      return unless @facet_item.respond_to? :hits

      @facet_item.hits
    end

    def items
      return unless @facet_item.respond_to? :items

      @facet_item.items
    end

    ##
    # Check if the query parameters have the given facet field with the
    # given value.
    def selected?
      search_state.filter(facet_config).include?(value)
    end

    def field_label
      facet_field_presenter.label
    end

    ##
    # Get the displayable version of a facet's value
    #
    # @return [String]
    def label
      label_value = if facet_item.respond_to? :label
                      facet_item.label
                    else
                      value
                    end

      if facet_config.helper_method
        view_context.public_send(facet_config.helper_method, label_value)
      elsif facet_config.query && facet_config.query[label_value]
        facet_config.query[label_value][:label]
      elsif value == Blacklight::SearchState::FilterField::MISSING
        I18n.t("blacklight.search.facets.missing")
      elsif facet_config.date
        localization_options = facet_config.date == true ? {} : facet_config.date
        I18n.l(Time.zone.parse(label_value), **localization_options)
      else
        label_value.to_s
      end
    end

    # Get the displayable version of the facet's value for use
    # in e.g. the constraints widget
    #
    # @return [String]
    def constraint_label
      label
    end

    def value
      if facet_item.respond_to? :value
        facet_item.value
      else
        facet_item
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
      view_context.search_action_path(path.filter(facet_config.key).remove(facet_item))
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

    def facet_field_presenter
      @facet_field_presenter ||= view_context.facet_field_presenter(facet_config, {})
    end
  end
end
