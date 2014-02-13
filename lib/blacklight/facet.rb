# These are methods that are used at both the view helper and controller layers
# They are only dependent on `blacklight_config` and `@response`
#
module Blacklight
  module Facet

    def facet_paginator field_config, display_facet
      Blacklight::Solr::FacetPaginator.new(display_facet.items, 
        sort: display_facet.sort,
        offset: display_facet.offset,     
        limit: facet_limit_for(field_config.field))
    end

    def facets_from_request(fields = facet_field_names)
      fields.map { |solr_field| facet_by_field_name(solr_field) }.compact
    end

    def facet_field_names
      blacklight_config.facet_fields.keys
    end

    def facet_configuration_for_field(field)
      blacklight_config.facet_fields[field] || Blacklight::Configuration::FacetField.new(:field => field).normalize!
    end


    # Get a FacetField object from the @response
    def facet_by_field_name solr_field
      case solr_field
        when String, Symbol
          extract_solr_facet_by_field_name(solr_field)
        when Blacklight::Configuration::FacetField
          extract_solr_facet_by_field_name(solr_field.field)
        else
          solr_field
        end
    end

    private

    # Get the solr response for the solr field :field
    def extract_solr_facet_by_field_name facet_name
      facet_field = facet_configuration_for_field(facet_name)
      case 
        when (facet_field.respond_to?(:query) and facet_field.query)
          create_rsolr_facet_field_response_for_query_facet_field facet_name, facet_field 
        when (facet_field.respond_to?(:pivot) and facet_field.pivot)
          create_rsolr_facet_field_response_for_pivot_facet_field facet_name, facet_field   
        else
          @response.facet_by_field_name(facet_name)
      end
    end

    def create_rsolr_facet_field_response_for_query_facet_field facet_name, facet_field
      salient_facet_queries = facet_field.query.map { |k, x| x[:fq] }
      items = []
      @response.facet_queries.select { |k,v| salient_facet_queries.include?(k) }.reject { |value, hits| hits == 0 }.map do |value,hits|
        salient_fields = facet_field.query.select { |key, val| val[:fq] == value }
        key = ((salient_fields.keys if salient_fields.respond_to? :keys) || salient_fields.first).first
        items << Blacklight::SolrResponse::Facets::FacetItem.new(:value => key, :hits => hits, :label => facet_field.query[key][:label])
      end
   
      Blacklight::SolrResponse::Facets::FacetField.new facet_name, items
    end


    def create_rsolr_facet_field_response_for_pivot_facet_field facet_name, facet_field
      items = []
      (@response.facet_pivot[facet_field.pivot.join(",")] || []).map do |lst|
        items << construct_pivot_field(lst)
      end
   
      Blacklight::SolrResponse::Facets::FacetField.new facet_name, items
    end

    def construct_pivot_field lst, parent_fq = {}
      items = []

      lst[:pivot].each do |i|
        items << construct_pivot_field(i, parent_fq.merge({ lst[:field] => lst[:value] }))
      end if lst[:pivot]

      Blacklight::SolrResponse::Facets::FacetItem.new(:value => lst[:value], :hits => lst[:count], :field => lst[:field], :items => items, :fq => parent_fq)

    end
  end
end
