# frozen_string_literal: true

module Blacklight
  class FacetFieldRangePresenter < Blacklight::FacetFieldPresenter
    delegate :response, to: :display_facet
    delegate :blacklight_config, to: :search_state

    # Paginator will return the selected item or if no facet is selected, the [Missing] facet.
    def paginator
      return unless display_facet

      @paginator ||= blacklight_config.facet_paginator_class.new(
        Array.wrap(selected_item || display_facet.items.select(&:missing)),
        sort: display_facet.sort,
        offset: display_facet.offset,
        prefix: display_facet.prefix,
        limit: facet_limit
      )
    end

    def selected_range
      values&.first
    end

    # Wraps selected range in Blacklight::Solr::Response::Facets::FacetItem object.
    #
    # @return [Blacklight::Solr::Response::Facets::FacetItem] if range is selected
    # @return [NilClass] if no range is selected
    def selected_item
      return unless selected_range

      Blacklight::Solr::Response::Facets::FacetItem.new(value: selected_range, hits: response.total)
    end

    # Returns true if [Missing] facet is selected.
    def missing_selected?
      selected_range == Blacklight::SearchState::FilterField::MISSING
    end
  end
end
