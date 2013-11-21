# -*- encoding : utf-8 -*-
module Blacklight::Solr
  

  # Pagination for facet values -- works by setting the limit to max
  # displayable. You have to ask Solr for limit+1, to get enough
  # results to see if 'more' are available'. That is, the all_facet_values
  # arg in constructor should be the result of asking solr for limit+1
  # values. 
  # This is a workaround for the fact that Solr itself can't compute
  # the total values for a given facet field,
  # so we cannot know how many "pages" there are.
  #
  class FacetPaginator    
    # What request keys will we use for the parameters need. Need to
    # make sure they do NOT conflict with catalog/index request params,
    # and need to make them accessible in a list so we can easily
    # strip em out before redirecting to catalog/index.
    # class variable (via class-level ivar)
    @request_keys = {:sort => :'facet.sort', :page => :'facet.page', :prefix => :'facet.prefix'}
    class << self; attr_accessor :request_keys end # create a class method
    def request_keys ; self.class.request_keys ; end # shortcut
    
    attr_reader :total, :items, :offset, :limit, :sort
    
    # all_facet_values is a list of facet value objects returned by solr,
    # asking solr for n+1 facet values.
    # options:
    # :limit =>  number to display per page, or (default) nil. Nil means
    #            display all with no previous or next. 
    # :offset => current item offset, default 0
    # :sort => 'count' or 'index', solr tokens for facet value sorting, default 'count'. 
    def initialize(all_facet_values, arguments)
      # to_s.to_i will conveniently default to 0 if nil
      @offset = arguments[:offset].to_s.to_i 
      @limit =  arguments[:limit].to_s.to_i if arguments[:limit]           
      # count is solr's default
      @sort = arguments[:sort] || "count"
      @can_filter  = arguments[:can_filter] || false
      
      total = all_facet_values.size
      if (@limit)
        @items = all_facet_values.slice(0, @limit)
        @has_next = total > @limit
        @has_previous = @offset > 0
      else # nil limit
        @items = all_facet_values
        @has_next = false
        @has_previous = false
      end
    end

    def current_page
      1 + @offset/@limit
    end
   
    def has_next?
      @has_next
    end

    def has_previous?
      @has_previous
    end

    def last_page?
      !has_next?
    end

    def first_page?
      !has_previous?
    end

    def can_filter?
      @can_filter
    end

   # Pass in a desired solr facet solr key ('count' or 'index', see
   # http://wiki.apache.org/solr/SimpleFacetParameters#facet.limit
   # under facet.sort ), and your current request params.
   # Get back params suitable to passing to an ActionHelper method for
   # creating a url, to resort by that method.
   def params_for_resort_url(sort_method, params)
     # When resorting, we've got to reset the offset to start at beginning,
     # no way to make it make sense otherwise.
     return params.merge(request_keys[:sort] => sort_method, request_keys[:page] => nil)
   end
   
   def params_for_filter_url(filter_str, params)
     # When filtering, we've got to reset the offset to start at beginning,
     # no way to make it make sense otherwise.
     return params.merge(request_keys[:prefix] => filter_str, request_keys[:page] => nil)
   end
    
  end
  
end
