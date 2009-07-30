module RSolr::Ext::Request
  
  autoload :Queryable, 'rsolr-ext/request/queryable.rb'
  
  class Standard
    
    include RSolr::Ext::Mapable
    include RSolr::Ext::Request::Queryable
    
    MAPPED_PARAMS = [
      :per_page,
      :page,
      :queries, # fielded queries
      :phrases, # quoted q param
      :filters, # fq params
      :phrase_filters, # quoted fq params,
      :facets
    ]
    
    def map_per_page(value,output)
      output[:rows] = value.to_i
    end
    
    def map_page(value,output)
      raise ':per_page must be set when using :page' unless output[:rows]
      page = value.to_s.to_i-1
      page = page < 1 ? 0 : page
      output[:start] = page * output[:rows]
    end
    
    def map_queries(value,output)
      output[:q] = append_to_param(output[:q], build_query(value, false))
    end
    
    def map_phrases(value,output)
      output[:q] = append_to_param(output[:q], build_query(value, true))
    end

    def map_filters(value,output)
      output[:fq] = append_to_param(output[:fq], build_query(value), false)
    end

    def map_phrase_filters(value,output)
      output[:fq] = append_to_param(output[:fq], build_query(value, true), false)
    end
    
    def map_facets(value,output)
      output[:facet] = true
      if value[:fields]
        fields = value[:fields].is_a?(Array) ? value[:fields] : [value[:fields]]
        fields.each do |f|
          output['facet.field'] ||= []
          output['facet.field'] << f
        end
      end
    end
    
  end
  
  class Dismax < Standard
    
  end
  
end