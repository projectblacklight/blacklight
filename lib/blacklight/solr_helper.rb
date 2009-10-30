# SolrHelper is a controller layer mixin. It is in the controller scope: request params, session etc.
# 
# NOTE: Be careful when creating variables here as they may be overriding something that already exists.
# The ActionController docs: http://api.rubyonrails.org/classes/ActionController/Base.html
#
# Override these methods in your own controller for customizations:
# 
# class CatalogController < ActionController::Base
#   
#   include Blacklight::SolrHelper
#   
#   def solr_search_params
#     super.merge :per_page=>10
#   end
#   
# end
#
module Blacklight::SolrHelper
  
  # When a request for a single solr document by id
  # is not successful, raise this:
  class InvalidSolrID < RuntimeError; end
  
  # returns a params hash for searching solr.
  # The CatalogController #index action uses this.
  def solr_search_params(extra_controller_params={})
    input = params.deep_merge(extra_controller_params)
    qt = input[:qt].blank? ? Blacklight.config[:default_qt] : input[:qt]
    
    # TODO -- remove :facets
    # when are we passing in "facets" here? just for tests? -- no, always.  
    #   Bess prefers to pass in the desired facets this way.  
    #   Naomi prefers it as part of the Solr request handler
    # ** we need to be consistent about what is getting passed in:
    # ** -- solr params or controller params that need to be mapped?
    facet_fields = input[:facets].blank? ? Blacklight.config[:facet][:field_names] : input[:facets]
    # add any facet fields from the argument list (that aren't in the config list)
    #  for example, if a selected facet value means a *new* facet is desired
    #   (Stanford is doing faux "hierarchical" facets this way;  the 
    #    hierarchical facet code for SOLR isn't fully baked yet and won't be
    #    included until Solr 1.5)
    if params.has_key?("facet.field")
      params["facet.field"].each do |ff|
        if !facet_fields.include?(ff)
          facet_fields << ff
        end
      end
    end
    
    # try a per_page, if it's not set, grab it from Blacklight.config
    per_page = input[:per_page].blank? ? (Blacklight.config[:index][:num_per_page] rescue 10) : input[:per_page]
    # limit to 100
    per_page = per_page.to_i > 100 ? 100 : per_page
    {
      :qt => qt,
      :per_page => per_page.to_i,
      :q => input[:q],
      :phrase_filters => input[:f],
      :facets => {:fields=>facet_fields},
      :page => input[:page],
      :sort => input[:sort],
      "spellcheck.q" => input[:q]
    }
  end
  
  # a solr query method
  # given a user query, return a solr response containing both result docs and facets
  # - mixes in the Blacklight::Solr::SpellingSuggestions module
  #   - the response will have a spelling_suggestions method
  def get_search_results(extra_controller_params={})
    Blacklight.solr.find self.solr_search_params(extra_controller_params)
  end
  
  # returns a params hash for finding a single solr document (CatalogController #show action)
  # If the id arg is nil, then the value is fetched from params[:id]
  # This method is primary called by the get_solr_response_for_doc_id method.
  def solr_doc_params(id=nil, extra_controller_params={})
    id ||= params[:id]
    # just to be consistent with the other solr param methods:
    input = params.deep_merge(extra_controller_params)
    {
      :qt => :document,
      :id => id
    }
  end
  
  # a solr query method
  # retrieve a solr document, given the doc id
  # TODO: shouldn't hardcode id field;  should be setable to unique_key field in schema.xml
  def get_solr_response_for_doc_id(id=nil, extra_controller_params={})
    solr_response = Blacklight.solr.find solr_doc_params(id, extra_controller_params)
    raise InvalidSolrID.new if solr_response.docs.empty?
    solr_response
  end
  
  # returns a params hash for a single facet field solr query.
  # used primary by the get_facet_pagination method
  def solr_facet_params(facet_field, extra_controller_params={})
    input = params.deep_merge(extra_controller_params)
    {
      :phrase_filters => input[:f],
      :q => input[:q],
      :facets => {:fields => facet_field},
      'facet.limit' => 6,
      'facet.offset' => input[:offset].to_i,
    }
  end
  
  # a solr query method
  # used to paginate through a single facet field's values
  # /catalog/facet/language_facet
  def get_facet_pagination(facet_field, extra_controller_params={})
    Blacklight::Solr::Facets.paginate solr_facet_params(facet_field, extra_controller_params)
  end
  
  # a solr query method
  # this is used when selecting a search result: we have a query and a 
  # position in the search results and possibly some facets
  def get_single_doc_via_search(extra_controller_params={})
    solr_params = solr_search_params(extra_controller_params)
    solr_params[:per_page] = 1
    solr_params[:fl] = '*'
    Blacklight.solr.find(solr_params).docs.first
  end
  
  # returns a solr params hash
  # if field is nil, the value is fetched from Blacklight.config[:index][:show_link]
  # the :fl (solr param) is set to the "field" value.
  # per_page is set to 10
  def solr_opensearch_params(field, extra_controller_params={})
    solr_params = solr_search_params(extra_controller_params)
    solr_params[:per_page] = 10
    solr_params[:fl] = Blacklight.config[:index][:show_link]
    solr_params
  end
  
  # a solr query method
  # does a standard search but returns a simplified object.
  # an array is returned, the first item is the query string,
  # the second item is an other array. This second array contains
  # all of the field values for each of the documents...
  # where the field is the "field" argument passed in.
  def get_opensearch_response(field=nil, extra_controller_params={})
    solr_params = solr_opensearch_params(extra_controller_params)
    response = Blacklight.solr.find(solr_params)
    a = [solr_params[:q]]
    a << response.docs.map {|doc| doc[solr_params[:fl]].to_s }
  end
  
end