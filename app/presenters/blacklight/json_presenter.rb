# frozen_string_literal: true
module Blacklight
  class JsonPresenter
    include Blacklight::Facet

    # @param [Solr::Response] response raw solr response.
    # @param [Configuration] blacklight_config the configuration
    def initialize(response, blacklight_config)
      @response = response
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config

    def documents
      @response.documents
    end

    # @return [Array<Blacklight::Solr::Response::Facets::FacetField>]
    def search_facets
      facets_from_request.select { |display_facet| display_facet.items.present? }
    end

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
