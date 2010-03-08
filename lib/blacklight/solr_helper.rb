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
  MaxPerPage = 100
  # When a request for a single solr document by id
  # is not successful, raise this:
  class InvalidSolrID < RuntimeError; end


 # returns a params hash for searching solr.
  # The CatalogController #index action uses this.
  # Solr parameters can come from a number of places. From lowest
  # precedence to highest:
  #  1. General defaults in blacklight config (are trumped by)
  #  2. defaults for the particular search field identified by  params[:search_field] (are trumped by) 
  #  3. certain parameters directly on input HTTP query params 
  #     * not just any parameter is grabbed willy nilly, only certain ones are allowed by HTTP input)
  #     * for legacy reasons, qt in http query does not over-ride qt in search field definition default. 
  #  4.  extra parameters passed in as argument.
  #
  # spellcheck.q will be supplied with the [:q] value unless specifically
  # specified otherwise. 
  #
  # Incoming parameter :f is mapped to :phrase_filter solr parameter.
  def solr_search_params(extra_controller_params={})
    # Order of precedence for all the places solr params can come from,
    # start lowest, and keep over-riding with higher. 
    ####
    # Start with general defaults from BL config.
    # TODO -- remove :facets
    # when are we passing in "facets" here? just for tests? -- no, always.  
    #   Bess prefers to pass in the desired facets this way.  
    #   Naomi prefers it as part of the Solr request handler
    # ** we need to be consistent about what is getting passed in:
    # ** -- solr params or controller params that need to be mapped?
    #   jrochkind 28-dec-09 likes it the way it is, where facets can be part
    #   of the solr request handler OR in Blacklight. If you don't want them
    #   in blacklight, just leave don't fill out the config.
    ####

    solr_parameters = {
      :qt => Blacklight.config[:default_qt],
      :facets => Blacklight.config[:facet][:field_names].clone,
      :per_page => (Blacklight.config[:index][:num_per_page] rescue "10")
    }

    
    ###
    # Merge in search field configured values, if present, over-writing general
    # defaults
    ###
    search_field_def = Blacklight.search_field_def_for_key(params[:search_field] || extra_controller_params[:search_field])
    
    solr_parameters[:qt] = search_field_def[:qt] if search_field_def
    
    if ( search_field_def && search_field_def[:solr_parameters])
      solr_parameters.merge!( search_field_def[:solr_parameters])
    end

    
    ###
    # Merge in certain values from HTTP query itelf
    ###
    # Omit empty strings and nil values. 
    [:facets, :f, :page, :sort, :per_page].each do |key|
      solr_parameters[key] = params[key] unless params[key].blank?      
    end
    # :q is meaningful as an empty string, should be used unless nil!
    [:q].each do |key|
      solr_parameters[key] = params[key] if params[key]
    end
        
    # qt is handled different for legacy reasons; qt in HTTP param can not
    # over-ride qt from search_field_def defaults, it's only used if there
    # was no qt from search_field_def_defaults
    unless params[:qt].blank? || ( search_field_def && search_field_def[:qt])
      solr_parameters[:qt] = params[:qt]
    end
    
    # add any facet fields params["facet.field"] that aren't already included
    #  for example, if a selected facet value means a *new* facet is desired
    #   (Stanford is doing faux "hierarchical" facets this way;  the 
    #    hierarchical facet code for SOLR isn't fully baked yet and won't be
    #    included until Solr 1.5)
    if params.has_key?("facet.field")
      params["facet.field"].each do |ff|
        if !solr_parameters[:facets].include?(ff)
          solr_parameters[:facets] << ff
        end
      end
    end

    
    ###
    # Merge in any values from extra_params argument. It doesn't seem like
    # we should have to take a slice of just certain keys, but legacy code
    # seems to put arguments in here that aren't really expected to turn
    # into solr params. 
    ###
    solr_parameters.deep_merge!(extra_controller_params.slice(:qt, :q, :facets,  :page, :per_page, :phrase_filters, :f, :fl, :sort, :qf, :df )   )

    
    ###
    # Defaults for otherwise blank values and normalization. 
    ###
    
    # TODO: Change calling code to expect this as a symbol instead of
    # a string, for consistency? :'spellcheck.q' is a symbol. Right now
    # callers assume a string. 
    solr_parameters["spellcheck.q"] = solr_parameters[:q] unless solr_parameters["spellcheck.q"]

    # And fix the 'facets' parameter to be the way the solr expects it.
    solr_parameters[:facets]= {:fields => solr_parameters[:facets]} if solr_parameters[:facets]
    
    # phrase_filters, map from :f. 
    if ( solr_parameters[:f])
      solr_parameters[:phrase_filters] = solr_parameters.delete(:f)      
    end

    # Facet 'more' limits. Add +1 to any configured facets limits,
    # also include 'nil' default limit.
    if ( default_limit = facet_limit_for(nil))
      solr_parameters[:"facet.limit"] = (default_limit + 1)                                 
    end
    facet_limit_hash.each_pair do |field_name, limit|
      next if field_name.nil? # skip the 'default' key      
      solr_parameters[:"f.#{field_name}.facet.limit"] = (limit + 1)
    end
    
    
    ###
    # Sanity/requirements checks.
    ###
    
    # limit to MaxPerPage (100). Tests want this to be a string not an integer,
    # not sure why. 
    solr_parameters[:per_page] = solr_parameters[:per_page].to_i > MaxPerPage ? MaxPerPage.to_s : solr_parameters[:per_page]

    return solr_parameters
    
  end
  
  # a solr query method
  # given a user query, return a solr response containing both result docs and facets
  # - mixes in the Blacklight::Solr::SpellingSuggestions module
  #   - the response will have a spelling_suggestions method
  # Returns a two-element array (aka duple) with first the solr response object,
  # and second an array of SolrDocuments representing the response.docs
  def get_search_results(extra_controller_params={})
  
  
    solr_response = Blacklight.solr.find(  self.solr_search_params(extra_controller_params) )

    document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc)}

    return [solr_response, document_list]
    
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
    document = SolrDocument.new(solr_response.docs.first)
    [solr_response, document]
  end
  
  # returns a params hash for a single facet field solr query.
  # used primary by the get_facet_pagination method.
  # Looks up Facet Paginator request params from current request
  # params to figure out sort and offset. 
  def solr_facet_params(facet_field, extra_controller_params={})
    input = params.deep_merge(extra_controller_params)

    # First start with a standard solr search params calculations,
    # for any search context in our request params. 
    solr_params = solr_search_params(extra_controller_params)
    
    # Now override with our specific things for fetching facet values
    solr_params[:facets] = {:fields => facet_field}
    solr_params['facet.limit'] ||= 6
    solr_params['facet.offset'] = input[  Blacklight::Solr::Facets::Paginator.request_keys[:offset]  ].to_i # will default to 0 if nil
    solr_params['facet.sort'] = input[  Blacklight::Solr::Facets::Paginator.request_keys[:sort] ]     
    solr_params[:rows] = 0

    return solr_params
  end
  
  # a solr query method
  # used to paginate through a single facet field's values
  # /catalog/facet/language_facet
  def get_facet_pagination(facet_field, extra_controller_params={})
    solr_params = solr_facet_params(facet_field, extra_controller_params)

    # Make the solr call
    response = Blacklight.solr.find(solr_params)
    
    # Actually create the paginator!
    return     Blacklight::Solr::Facets::Paginator.new(response.facets.first.items, 
      :offset => solr_params['facet.offset'], 
      :limit => solr_params['facet.limit'],
      :sort => response["responseHeader"]["params"]["facet.sort"]
    )
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