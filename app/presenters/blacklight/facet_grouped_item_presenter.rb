# frozen_string_literal: true

module Blacklight
  class FacetGroupedItemPresenter < Blacklight::FacetItemPresenter
    attr_reader :group

    delegate :key, to: :facet_config

    def initialize(group, facet_item, facet_config, view_context, facet_field, search_state = view_context.search_state)
      @group = group
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
      group.include?(facet_item)
    end

    # @private
    def remove_href(path = search_state)
      new_state = path.filter(facet_config).remove(group)
      new_state = new_state.filter(facet_config).add(group - [facet_item])

      view_context.search_action_path(new_state)
    end

    # @private
    def add_href(_path_options = {})
      if facet_config.url_method
        return view_context.public_send(facet_config.url_method, facet_config.key, facet_item)
      end

      new_state = search_state.filter(facet_config).remove(@group)
      new_state = new_state.filter(facet_config).add(@group + [facet_item])

      view_context.search_action_path(new_state)
    end
  end
end
