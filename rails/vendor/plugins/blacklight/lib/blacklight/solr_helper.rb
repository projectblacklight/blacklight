module Blacklight::SolrHelper
  
# TODO: for tailored searches (e.g. fielded ones), qt param will need to be passed in
    
  # given a user query, return a solr response containing both result docs
  # and facets
  def get_search_results(params={})
    args = params ? params.symbolize_keys : {}
    args[:qt] ||= Blacklight.config[:default_qt]
    args[:facets] ||= Blacklight.config[:facet][:field_names]
    args[:per_page] ||= Blacklight.config[:index][:num_per_page] rescue 10
    
    mapper = RSolr::Ext::Request::Standard.new
    solr_params = mapper.map({
      :q => args[:q],
      :phrase_filters => args[:f],
      :qt => args[:qt],
      :facets => {:fields=>args[:facets]},
      :per_page => args[:per_page].to_i > 100 ? 100 : args[:per_page],
      :page => args[:page],
      :sort => args[:sort]
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
  
  # used to paginate through a single facet field's values
  def get_facet_pagination(facet_field, query_type=nil)
    query_type ||= Blacklight.config[:default_qt]
    mapper = RSolr::Ext::Request::Standard.new
    limit = (params[:limit] || 6)
    solr_params = mapper.map({
      :qt => query_type,
      :q => params[:q],
      :phrase_filters => params[:f],
      :facet => true,
      'facet.offset' => params[:offset],
      'facet.limit' => limit
    })
    raw_response = Blacklight.solr.select(solr_params)
    response = RSolr::Ext::Response::Standard.new(raw_response)
    Blacklight::FacetPagination.new(response.facets.first.items, params[:offset], limit)
  end
  
  # this is used when selecting a search result: we have a query and a 
  # position in the search results and possibly some facets
  def get_single_doc_via_search(params={})
    args = params ? params.symbolize_keys : {}
    args[:page] ||= 1
    args[:qt] ||= Blacklight.config[:default_qt]
    mapper = RSolr::Ext::Request::Standard.new
    solr_params = mapper.map({
      :q => args[:q], 
      :phrase_filters => args[:f],
      :qt => args[:qt],
      :per_page => 1,
      :page => args[:page],
      :facet => false,
      :fl => '*'
    })
    raw_response = Blacklight.solr.select(solr_params)
    response = RSolr::Ext::Response::Standard.new(raw_response)
    response.docs.first
  end

end