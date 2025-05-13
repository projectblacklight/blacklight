# frozen_string_literal: true

module Blacklight
  module Facets
    class FilterComponent < Blacklight::Component
      # @params [Blacklight::FacetFieldPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
      end

      def render?
        index_range && @presenter.display_facet.index?
      end

      def index_range
        @presenter.facet_field.index_range
      end

      def prefix
        @presenter.paginator.prefix
      end

      def clear_facet_prefix_url
        @presenter.paginator.params_for_resort_url('index', @presenter.search_state.to_h.except(@presenter.paginator.request_keys[:prefix]))
      end

      def facet_prefix_url(letter)
        @presenter.paginator.params_for_resort_url('index', @presenter.search_state.to_h.merge(@presenter.paginator.request_keys[:prefix] => letter))
      end
    end
  end
end
