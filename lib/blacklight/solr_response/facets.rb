require 'ostruct'

module Blacklight::SolrResponse::Facets
  
  # represents a facet value; which is a field value and its hit count
  class FacetItem < OpenStruct
    def initialize *args
      options = args.extract_options!

      # Backwards-compat method signature
      value = args.shift
      hits = args.shift

      options[:value] = value if value
      options[:hits] = hits if hits
      
      super(options)
    end

    def label
      super || value
    end

    def as_json(props = nil)
      table.as_json(props)
    end
  end
  
  # represents a facet; which is a field and its values
  class FacetField
    attr_reader :name, :items
    def initialize name, items, options = {}
      @name, @items = name, items
      @options = options
    end

    def limit
      @options[:limit] || solr_default_limit
    end

    def sort
      @options[:sort] || solr_default_sort
    end

    def offset
      @options[:offset] || solr_default_offset
    end
    
    private
    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.limit
    def solr_default_limit
      100
    end
    
    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.sort
    def solr_default_sort
      if limit > 0
        'count'
      else
        'index'
      end
    end
    
    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.offset
    def solr_default_offset
      0
    end
    
  end
  
  # @response.facets.each do |facet|
  #   facet.name
  #   facet.items
  # end
  # "caches" the result in the @facets instance var
  def facets
    @facets ||= begin
      facet_fields.map do |(facet_field_name,values_and_hits)|
        items = []
        options = {}
        values_and_hits.each_slice(2) do |k,v|
          items << FacetItem.new(:value => k, :hits => v)
        end
        options[:sort] = (params[:"f.#{facet_field_name}.facet.sort"] || params[:'facet.sort'])
        if params[:"f.#{facet_field_name}.facet.limit"] || params[:"facet.limit"]
          options[:limit] = (params[:"f.#{facet_field_name}.facet.limit"] || params[:"facet.limit"]).to_i
        end

        if params[:"f.#{facet_field_name}.facet.offset"] || params[:'facet.offset']
          options[:offset] = (params[:"f.#{facet_field_name}.facet.offset"] || params[:'facet.offset']).to_i
        end
        FacetField.new(facet_field_name, items, options)
      end
    end
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
