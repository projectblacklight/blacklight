module Blacklight::Elasticsearch
  class SearchBuilder < Blacklight::SearchBuilder
    self.default_processor_chain = [:default_parameters, :build_query, :add_filters, :add_aggregations, :add_pagination, :add_sort]

    ####
    # Start with general defaults from BL config. Need to use custom
    # merge to dup values, to avoid later mutating the original by mistake.
    def default_parameters(es_parameters)
      return unless blacklight_config.default_elasticsearch_params

      blacklight_config.default_elasticsearch_params.each do |key, value|
        es_parameters[key] = if value.respond_to? :deep_dup
          value.deep_dup
        elsif value.respond_to? :dup and value.duplicable?
          value.dup
        else
          value
        end
      end
    end

    def build_query(es_parameters)
      return unless blacklight_params[:q]
      es_parameters[:query] ||= {}
      
      if blacklight_params[:q].is_a? Hash
        es_parameters[:query][:match] ||= {}

        blacklight_params[:q].each do |k,v|
          es_parameters[:query][:match][k] = v
        end
        return
      end

      if search_field and search_field.template
        es_parameters[:query][:template] = search_field.template.dup
        es_parameters[:query][:template][:params] ||= {}
        es_parameters[:query][:template][:params][:q] = blacklight_params[:q]
      else
        es_parameters[:query][:match] ||= {}
        es_parameters[:query][:match][:_all] = blacklight_params[:q]
      end
    end
    
    def add_filters(es_parameters)
      if blacklight_params[:f]
        es_parameters[:query] ||= {}
        es_parameters[:query][:filtered] ||= {}
        es_parameters[:query][:filtered][:filter] ||= {}
        es_parameters[:query][:filtered][:filter][:term] ||= {}
        
        
        blacklight_params[:f].each_pair do |facet_field, value_list|
          
          facet_config = blacklight_config.facet_fields[facet_field]

          field = facet_config.field if facet_config
          field ||= facet_field

          es_parameters[:query][:filtered][:filter][:term][field] ||= value_list
        end      
      end
    end

    def add_aggregations(es_parameters)
      es_parameters[:aggregations] ||= {}

      blacklight_config.facet_fields.select { |field_name,facet|
        facet.include_in_request || (facet.include_in_request.nil? && blacklight_config.add_facet_fields_to_solr_request)
      }.each do |key, facet_config|
        es_parameters[:aggregations][facet_config.field] = { terms: { field: facet_config.field } }
      end
    end

    def add_pagination(es_parameters)
      es_parameters[:from] = start
      es_parameters[:size] = rows
    end

    def add_sort(es_parameters)
      es_parameters[:sort] = sort unless sort.blank?
    end

    def query(*args)
      super.except(:fl, :facet)
    end
  end
end