# frozen_string_literal: true
module Blacklight
  class JsonPresenter
    class_attribute :facet_list_presenter
    self.facet_list_presenter = Blacklight::FacetListPresenter
    include Blacklight::Facet

    # @param [Solr::Response] response raw solr response.
    # @param [Array] facets list of facets
    def initialize(response, search_state)
      @response = response
      @search_state = search_state
    end

    attr_reader :search_state
    delegate :blacklight_config, to: :search_state

    def facets
      @facets_presenter ||= facet_list_presenter.new(@response, search_state.controller)
    end

    def documents
      @response.documents
    end

    def search_facets_as_json
      facets.as_json
    end
    deprecation_deprecate search_facets_as_json: 'search_facets_as_json is deprecated and will be removed in Blacklight 8. Use facets.as_json instead.'

    # extract the pagination info from the response object
    def pagination_info
      h = {}

      [:current_page, :next_page, :prev_page, :total_pages,
       :limit_value, :offset_value, :total_count,
       :first_page?, :last_page?].each do |k|
        h[k] = @response.send(k)
      end

      h
    end
  end
end
