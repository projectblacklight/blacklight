# frozen_string_literal: true
module Blacklight
  class JsonPresenter
    include Blacklight::Facet

    # @param [Solr::Response] response raw solr response.
    # @param [Array<Solr::Response::Facets::FacetField>] facets list of facets
    # @param [Configuration] blacklight_config the configuration
    def initialize(response, facets, blacklight_config)
      @response = response
      @facets = facets
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config

    def documents
      @response.documents
    end

    def search_facets_as_json
      @facets.map do |display_facet|
        next if display_facet.items.empty?
        f = display_facet.as_json
        f.stringify_keys!
        f.delete "options"
        f["label"] = facet_configuration_for_field(f["name"]).label
        f["items"] = f["items"].as_json.each do |i|
          i['label'] ||= i['value']
        end
        f
      end.compact
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
