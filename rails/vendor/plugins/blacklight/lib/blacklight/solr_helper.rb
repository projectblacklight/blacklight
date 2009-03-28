module Blacklight::SolrHelper
  
  DisplayFields.init
  
# TODO: for tailored searches (e.g. fielded ones), qt param will need to be passed in
    
  # given a user query, return a solr response containing both result docs
  # and facets
  def get_search_results(user_query, facets=nil, num_per_page=nil, page=1)
    
    num_per_page ||= DisplayFields.index_view[:num_per_page] rescue 10
    
    mapper = RSolr::Ext::Request::Standard.new
    
    solr_params = mapper.map({
      :q=>user_query,
      :phrase_filters => facets,
      :qt=>:search,
      :per_page=>num_per_page,
      :page=>page
    })
    raw_response = Blacklight.solr.select(solr_params)
    
    RSolr::Ext::Response::Standard.new(raw_response)
  end
  
  # retrieve a solr document, given the doc id
  def get_solr_response_for_doc_id(doc_id)
    # TODO: shouldn't hardcode id field;  should be setable to unique_key field in schema.xml
    #   Note: hardcoding is also in rsolr connection base find_by_id() method
    solr_params = {:qt=>:document, :id=>doc_id}
    raw_response = Blacklight.solr.select(solr_params)
    RSolr::Ext::Response::Standard.new(raw_response)
  end
  
  # used to paginate through a single facet field'Ås values
  def get_facet_pagination(facet_field)
    mapper = RSolr::Ext::Request::Standard.new
    limit = (params[:limit] || 6)
    solr_params = mapper.map({
      :qt=>:search,
      :q=>params[:q],
      :phrase_filters => params[:f],
      :facet=>true,
      'facet.offset' => params[:offset],
      'facet.limit' => limit
    })
    raw_response = Blacklight.solr.select(solr_params)
    response = RSolr::Ext::Response::Standard.new(raw_response)
    Blacklight::FacetPagination.new(response.facets.first.items, params[:offset], limit)
  end
  
  # this is used when selecting a search result: we have a query and a 
  # position in the search results and possibly some facets
  def get_single_doc_via_search(query, position=1, facets=nil)
    mapper = RSolr::Ext::Request::Standard.new
    solr_params = mapper.map({
      :q=>query, 
      :phrase_filters => facets,
      :qt=>:search,
      :per_page=>1,
      :page=>position,
      :facet=>false,
      :fl=>'*'
    })
    raw_response = Blacklight.solr.select(solr_params)
    response = RSolr::Ext::Response::Standard.new(raw_response)
    response.docs.first
  end

end