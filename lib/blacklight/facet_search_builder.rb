# frozen_string_literal: true

module Blacklight
  class FacetSearchBuilder < AbstractSearchBuilder
    def facet_suggestion_query=(value)
      params_will_change!
      @facet_suggestion_query = value
    end

    def facet_suggestion_query(value = nil)
      if value
        self.facet_suggestion_query = value
        return self
      end
      @facet_suggestion_query
    end
  end
end
