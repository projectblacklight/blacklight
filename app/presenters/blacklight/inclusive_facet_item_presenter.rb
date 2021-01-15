# frozen_string_literal: true

module Blacklight
  class InclusiveFacetItemPresenter < Blacklight::FacetItemPresenter
    ##
    # Get the displayable version of a facet's value
    #
    # @return [String]
    def label
      view_context.safe_join(
        Array(facet_item).map { |value| Blacklight::FacetGroupedItemPresenter.new(facet_item, value, facet_config, view_context, facet_field, search_state).label },
        view_context.t('blacklight.advanced_search.or_html')
      )
    end
  end
end
