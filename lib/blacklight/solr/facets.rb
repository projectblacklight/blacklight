module Blacklight::Solr::Facets
  

  # Pagination for facet values -- works by setting the limit to (max + 1)
  # If limit is 6, then the resulting facet value items.size==5
  # This is a workaround for the fact that Solr itself can't compute
  # the total values for a given facet field,
  # so we cannot know how many "pages" there are.
  #
  class Paginator
    
    attr_reader :total, :items, :offset, :limit, :sort

    def initialize(all_facet_values, arguments)
      @offset = arguments[:offset].to_s.to_i # will default to 0 if nil
      @limit = arguments[:limit] ? arguments[:limit].to_s.to_i : 6
      @sort = arguments[:sort] || "count" # count is solr's default
      
      total = all_facet_values.size
      @items = all_facet_values.slice(0, limit-1)
      @has_next = total > @limit
      @has_previous = @offset > 0
    end

    def has_next?
      @has_next
    end

    # Pass in your current request params, returns a param hash
    # suitable to passing to an ActionHelper method (resource-based url_for, or
    # link_to or url_for) navigating to the next facet value batch. Returns nil 
    # if there is no has_next?
    def params_for_next_url(params)
      return nil unless has_next?
      
      return params.merge(:offset => offset + (limit-1) )
    end

    def has_previous?
      @has_previous
    end
    
    # Pass in your current request params, returns a param hash
    # suitable to passing to an ActionHelper method (resource-based url_for, or
    # link_to or url_for) navigating to the previous facet value batch. Returns
    # nil if there is no has_previous?
    def params_for_previous_url(params)
      return nil unless has_previous?

      return params.merge(:offset => offset - (limit-1) )
    end

   # Pass in a desired solr facet solr key ('count' or 'index', see
   # http://wiki.apache.org/solr/SimpleFacetParameters#facet.limit
   # under facet.sort ), and your current request params.
   # Get back params suitable to passing to an ActionHelper method for
   # creating a url, to resort by that method.
   def params_for_resort_url(sort_method, params)
     # When resorting, we've got to reset the offset to start at beginning,
     # no way to make it make sense otherwise.
     return params.merge(:sort => sort_method,
                         :offset => 0)
   end
    
  end
  
end