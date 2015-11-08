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
  class FacetPaginator < Blacklight::FacetPaginator
    # all_facet_values is a list of facet value objects returned by solr,
    # asking solr for n+1 facet values.
    # options:
    # :limit =>  number to display per page, or (default) nil. Nil means
    #            display all with no previous or next. 
    # :offset => current item offset, default 0
    # :sort => 'count' or 'index', solr tokens for facet value sorting, default 'count'. 
    def initialize(all_facet_values, arguments = {})
      super

      # count is solr's default
      @sort ||= if @limit.to_i > 0
                  'count'
                else
                  'index'
                end
    end
  end
end
