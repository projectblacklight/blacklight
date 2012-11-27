module Blacklight::SolrResponse::Facets
  
  # represents a facet value; which is a field value and its hit count
  class FacetItem
    attr_reader :value, :hits
    def initialize value, hits
      @value, @hits = value, hits
    end
  end
  
  # represents a facet; which is a field and its values
  class FacetField
    attr_reader :name, :items
    def initialize name, items
      @name, @items = name, items
    end
  end
  
  # @response.facets.each do |facet|
  #   facet.name
  #   facet.items
  # end
  # "caches" the result in the @facets instance var
  def facets
    @facets ||= (
      facet_fields.map do |(facet_field_name,values_and_hits)|
        items = []
        values_and_hits.each_slice(2) do |k,v|
          items << FacetItem.new(k, v)
        end
        FacetField.new(facet_field_name, items)
      end
    )
  end
  
  # pass in a facet field name and get back a Facet instance
  def facet_by_field_name(name)
    @facets_by_field_name ||= {}
    @facets_by_field_name[name] ||= (
      facets.detect{|facet|facet.name.to_s == name.to_s}
    )
  end
  
  def facet_counts
    @facet_counts ||= self['facet_counts'] || {}
  end

  # Returns the hash of all the facet_fields (ie: {'instock_b' => ['true', 123, 'false', 20]}
  def facet_fields
    @facet_fields ||= facet_counts['facet_fields'] || {}
  end

  # Returns all of the facet queries
  def facet_queries
    @facet_queries ||= facet_counts['facet_queries'] || {}
  end
  
  # Returns all of the facet queries
  def facet_pivot
    @facet_pivot ||= facet_counts['facet_pivot'] || {}
  end
  
end # end Facets
