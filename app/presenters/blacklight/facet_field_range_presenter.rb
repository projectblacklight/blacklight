# frozen_string_literal: true

module Blacklight
  class FacetFieldRangePresenter < Blacklight::FacetFieldPresenter
    delegate :response, to: :display_facet
    delegate :blacklight_config, to: :search_state

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

    def selected_item
      return unless selected_range

      Blacklight::Solr::Response::Facets::FacetItem.new(value: selected_range, hits: response.total)
    end

    def missing_selected?
      selected_range == Blacklight::SearchState::FilterField::MISSING
    end
  end
end
