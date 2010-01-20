module Blacklight::Solr::Facets

  # shortcut method for setting up a Paginator instance
  def self.paginate(params)
    params['facet.limit'] ||= 6
    raise '[:facet][:fields] is required' if ! params[:facets] or ! params[:facets][:fields]
    raise "['facet.offset'] is required" unless params['facet.offset']
    params[:rows] = 0
    response = Blacklight.solr.find(params)
    Paginator.new(response.facets.first.items, params['facet.offset'], params['facet.limit'])
  end
  
  #
  # Pagination for facet values -- works by setting the limit to (max + 1)
  # If limit is 6, then the resulting facet value items.size==5
  # This is a workaround for the fact that Solr itself can't compute
  # the total values for a given facet field,
  # so we cannot know how many "pages" there are.
  #
  class Paginator
    
    attr_reader :total, :items, :previous_offset, :next_offset

    def initialize(all_facet_values, offset, limit)
      offset = offset.to_s.to_i
      limit = limit.to_s.to_i
      total = all_facet_values.size
      @items = all_facet_values.slice(0, limit-1)
      @has_next = total > limit
      @has_previous = offset > 0
      @next_offset = offset + (limit-1)
      @previous_offset = offset - (limit-1)
    end

    def has_next?
      @has_next
    end

    def has_previous?
      @has_previous
    end
    
  end
  
end