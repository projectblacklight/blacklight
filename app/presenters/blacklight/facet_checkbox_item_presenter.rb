# frozen_string_literal: true

module Blacklight
  class FacetCheckboxItemPresenter < Blacklight::FacetItemPresenter
    # Check if the query parameters have any inclusive facets with the given value
    # @return [Boolean]
    def selected?
      search_state.filter(facet_config).values(except: [:filters, :missing]).flatten.include?(value)
    end
  end
end
