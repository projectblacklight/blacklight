# -*- encoding : utf-8 -*-
# SolrHelper is a controller layer mixin. It is in the controller scope: request params, session etc.
# 
# NOTE: Be careful when creating variables here as they may be overriding something that already exists.
# The ActionController docs: http://api.rubyonrails.org/classes/ActionController/Base.html
#
# Override these methods in your own controller for customizations:
# 
#   class CatalogController < ActionController::Base
#   
#     include Blacklight::Catalog
#   
#     def solr_search_params
#       super.merge :per_page=>10
#     end
#   end
#
# Or by including in local extensions:
#   module LocalSolrHelperExtension
#     [ local overrides ]
#   end
#
#   class CatalogController < ActionController::Base
#   
#     include Blacklight::Catalog
#     include LocalSolrHelperExtension
#   
#     def solr_search_params
#       super.merge :per_page=>10
#     end
#   end
#
# Or by using ActiveSupport::Concern:
#
#   module LocalSolrHelperExtension
#     extend ActiveSupport::Concern
#     include Blacklight::SolrHelper
#
#     [ local overrides ]
#   end
#
#   class CatalogController < ApplicationController
#     include LocalSolrHelperExtension
#     include Blacklight::Catalog
#   end  

module Blacklight::SolrHelper
  extend ActiveSupport::Concern
  extend Deprecation
  include Blacklight::SearchFields
  include Blacklight::Facet
  include ActiveSupport::Benchmarkable

  included do
    if self.respond_to?(:helper_method)
      helper_method(:facet_limit_for)
    end

    include Blacklight::RequestBuilders

  end

  def force_to_utf8(value)
    case value
    when Hash
      value.each { |k, v| value[k] = force_to_utf8(v) }
    when Array
      value.each { |v| force_to_utf8(v) }
    when String
      value.force_encoding("utf-8")  if value.respond_to?(:force_encoding) 
    end
    value
  end
  
  ##
  # Execute a solr query
  # @see [RSolr::Client#send_and_receive]
  # @overload find(solr_path, params)
  #   Execute a solr query at the given path with the parameters
  #   @param [String] solr path (defaults to blacklight_config.solr_path)
  #   @param [Hash] parameters for RSolr::Client#send_and_receive
  # @overload find(params)
  #   @param [Hash] parameters for RSolr::Client#send_and_receive
  # @return [Blacklight::SolrResponse] the solr response object
  def find(*args)
    # In later versions of Rails, the #benchmark method can do timing
    # better for us. 
    benchmark("Solr fetch", level: :debug) do
      solr_params = args.extract_options!
      path = args.first || blacklight_config.solr_path
      solr_params[:qt] ||= blacklight_config.qt
      # delete these parameters, otherwise rsolr will pass them through.
      key = blacklight_config.http_method == :post ? :data : :params
      res = blacklight_solr.send_and_receive(path, {key=>solr_params.to_hash, method:blacklight_config.http_method})
      
      solr_response = Blacklight::SolrResponse.new(force_to_utf8(res), solr_params)

      Rails.logger.debug("Solr query: #{solr_params.inspect}")
      Rails.logger.debug("Solr response: #{solr_response.inspect}") if defined?(::BLACKLIGHT_VERBOSE_LOGGING) and ::BLACKLIGHT_VERBOSE_LOGGING
      solr_response
    end
  rescue Errno::ECONNREFUSED => e
    raise Blacklight::Exceptions::ECONNREFUSED.new("Unable to connect to Solr instance using #{blacklight_solr.inspect}")
  end
    
  
  # A helper method used for generating solr LocalParams, put quotes
  # around the term unless it's a bare-word. Escape internal quotes
  # if needed. 
  def solr_param_quote(val, options = {})
    options[:quote] ||= '"'
    unless val =~ /^[a-zA-Z0-9$_\-\^]+$/
      val = options[:quote] +
        # Yes, we need crazy escaping here, to deal with regexp esc too!
        val.gsub("'", "\\\\\'").gsub('"', "\\\\\"") + 
        options[:quote]
    end
    return val
  end
    
  # a solr query method
  # given a user query, return a solr response containing both result docs and facets
  # - mixes in the Blacklight::Solr::SpellingSuggestions module
  #   - the response will have a spelling_suggestions method
  # Returns a two-element array (aka duple) with first the solr response object,
  # and second an array of SolrDocuments representing the response.docs
  def get_search_results(user_params = params || {}, extra_controller_params = {})
    solr_response = query_solr(user_params, extra_controller_params)

    case
    when (solr_response.grouped? && grouped_key_for_results)
      [solr_response.group(grouped_key_for_results), []]
    when (solr_response.grouped? && solr_response.grouped.length == 1)
      [solr_response.grouped.first, []]
    else
      [solr_response, solr_response.documents]
    end
  end

  	
  # a solr query method
  # given a user query,
  # @return [Blacklight::SolrResponse] the solr response object
  def query_solr(user_params = params || {}, extra_controller_params = {})
    solr_params = self.solr_search_params(user_params).merge(extra_controller_params)

    find(solr_params)
  end
  
  # returns a params hash for finding a single solr document (CatalogController #show action)
  # If the id arg is nil, then the value is fetched from params[:id]
  # This method is primary called by the get_solr_response_for_doc_id method.
  def solr_doc_params(id=nil)
    id ||= params[:id]

    # add our document id to the document_unique_id_param query parameter
    p = blacklight_config.default_document_solr_params.merge({
      # this assumes the request handler will map the unique id param
      # to the unique key field using either solr local params, the 
      # real-time get handler, etc.
      blacklight_config.document_unique_id_param => id
    })

    p[:qt] ||= blacklight_config.document_solr_request_handler

    p
  end
  
  # a solr query method
  # retrieve a solr document, given the doc id
  # @return [Blacklight::SolrResponse, Blacklight::SolrDocument] the solr response object and the first document
  def get_solr_response_for_doc_id(id=nil, extra_controller_params={})
    solr_params = solr_doc_params(id).merge(extra_controller_params)
    solr_response = find(blacklight_config.document_solr_path, solr_params)
    raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.docs.empty?
    [solr_response, solr_response.documents.first]
  end
  
  # given a field name and array of values, get the matching SOLR documents
  # @return [Blacklight::SolrResponse, Array<Blacklight::SolrDocument>] the solr response object and a list of solr documents
  def get_solr_response_for_field_values(field, values, extra_solr_params = {})
    q = if Array(values).empty?
      "NOT *:*"
    else
      "#{field}:(#{ Array(values).map { |x| solr_param_quote(x)}.join(" OR ")})"
    end

    solr_params = {
      :defType => "lucene",   # need boolean for OR
      :q => q,
      # not sure why fl * is neccesary, why isn't default solr_search_params
      # sufficient, like it is for any other search results solr request? 
      # But tests fail without this. I think because some functionality requires
      # this to actually get solr_doc_params, not solr_search_params. Confused
      # semantics again. 
      :fl => "*",  
      :facet => 'false',
      :spellcheck => 'false'
    }.merge(extra_solr_params)
    
    solr_response = find(self.solr_search_params().merge(solr_params) )
    [solr_response, solr_response.documents]
  end
  
  # returns a params hash for a single facet field solr query.
  # used primary by the get_facet_pagination method.
  # Looks up Facet Paginator request params from current request
  # params to figure out sort and offset.
  # Default limit for facet list can be specified by defining a controller
  # method facet_list_limit, otherwise 20. 
  def solr_facet_params(facet_field, user_params=params || {}, extra_controller_params={})
    input = user_params.deep_merge(extra_controller_params)
    facet_config = blacklight_config.facet_fields[facet_field]

    # First start with a standard solr search params calculations,
    # for any search context in our request params. 
    solr_params = solr_search_params(user_params).merge(extra_controller_params)
    
    # Now override with our specific things for fetching facet values
    solr_params[:"facet.field"] = with_ex_local_param((facet_config.ex if facet_config.respond_to?(:ex)), facet_field)

    limit =  
      if respond_to?(:facet_list_limit)
        facet_list_limit.to_s.to_i
      elsif solr_params["facet.limit"] 
        solr_params["facet.limit"].to_i
      else
        20
      end

    # Need to set as f.facet_field.facet.* to make sure we
    # override any field-specific default in the solr request handler. 
    solr_params[:"f.#{facet_field}.facet.limit"]  = limit + 1
    solr_params[:"f.#{facet_field}.facet.offset"] = ( input.fetch(Blacklight::Solr::FacetPaginator.request_keys[:page] , 1).to_i - 1 ) * ( limit )
    solr_params[:"f.#{facet_field}.facet.sort"] = input[  Blacklight::Solr::FacetPaginator.request_keys[:sort] ] if  input[  Blacklight::Solr::FacetPaginator.request_keys[:sort] ]   
    solr_params[:rows] = 0

    return solr_params
  end
  
  ##
  # Get the solr response when retrieving only a single facet field
  # @return [Blacklight::SolrResponse] the solr response
  def get_facet_field_response(facet_field, user_params = params || {}, extra_controller_params = {})
    solr_params = solr_facet_params(facet_field, user_params, extra_controller_params)
    # Make the solr call
    find(solr_params)
  end

  # a solr query method
  # used to paginate through a single facet field's values
  # /catalog/facet/language_facet
  def get_facet_pagination(facet_field, user_params=params || {}, extra_controller_params={})
    # Make the solr call
    response = get_facet_field_response(facet_field, user_params, extra_controller_params)

    limit = response.params[:"f.#{facet_field}.facet.limit"].to_s.to_i - 1

    # Actually create the paginator!
    # NOTE: The sniffing of the proper sort from the solr response is not
    # currently tested for, tricky to figure out how to test, since the
    # default setup we test against doesn't use this feature. 
    return     Blacklight::Solr::FacetPaginator.new(response.facets.first.items, 
      :offset => response.params[:"f.#{facet_field}.facet.offset"], 
      :limit => limit,
      :sort => response.params[:"f.#{facet_field}.facet.sort"] || response.params["facet.sort"]
    )
  end
  deprecation_deprecate :get_facet_pagination
  
  # a solr query method
  # this is used when selecting a search result: we have a query and a 
  # position in the search results and possibly some facets
  # Pass in an index where 1 is the first document in the list, and
  # the Blacklight app-level request params that define the search. 
  # @return [Blacklight::SolrDocument, nil] the found document or nil if not found
  def get_single_doc_via_search(index, request_params)
    solr_params = solr_search_params(request_params)

    solr_params[:start] = (index - 1) # start at 0 to get 1st doc, 1 to get 2nd.    
    solr_params[:rows] = 1
    solr_params[:fl] = '*'
    solr_response = find(solr_params)
    solr_response.documents.first
  end
  deprecation_deprecate :get_single_doc_via_search

  # Get the previous and next document from a search result
  # @return [Blacklight::SolrResponse, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
  def get_previous_and_next_documents_for_search(index, request_params, extra_controller_params={})

    solr_params = solr_search_params(request_params).merge(extra_controller_params)

    if index > 0
      solr_params[:start] = index - 1 # get one before
      solr_params[:rows] = 3 # and one after
    else
      solr_params[:start] = 0 # there is no previous doc
      solr_params[:rows] = 2 # but there should be one after
    end

    solr_params[:fl] = '*'
    solr_params[:facet] = false
    solr_response = find(solr_params)

    document_list = solr_response.documents

    # only get the previous doc if there is one
    prev_doc = document_list.first if index > 0
    next_doc = document_list.last if (index + 1) < solr_response.total

    [solr_response, [prev_doc, next_doc]]
  end
    
  # returns a solr params hash
  # the :fl (solr param) is set to the "field" value.
  # per_page is set to 10
  def solr_opensearch_params(field=nil)
    solr_params = solr_search_params
    solr_params[:per_page] = 10
    solr_params[:fl] = field || blacklight_config.view_config('opensearch').title_field
    solr_params
  end
  
  # a solr query method
  # does a standard search but returns a simplified object.
  # an array is returned, the first item is the query string,
  # the second item is an other array. This second array contains
  # all of the field values for each of the documents...
  # where the field is the "field" argument passed in.
  def get_opensearch_response(field=nil, extra_controller_params={})
    solr_params = solr_opensearch_params().merge(extra_controller_params)
    response = find(solr_params)
    a = [solr_params[:q]]
    a << response.docs.map {|doc| doc[solr_params[:fl]].to_s }
  end
  
  
  
  # Look up facet limit for given facet_field. Will look at config, and
  # if config is 'true' will look up from Solr @response if available. If
  # no limit is avaialble, returns nil. Used from #solr_search_params
  # to supply f.fieldname.facet.limit values in solr request (no @response
  # available), and used in display (with @response available) to create
  # a facet paginator with the right limit. 
  def facet_limit_for(facet_field)
    facet = blacklight_config.facet_fields[facet_field]
    return if facet.blank?

    if facet.limit and @response and @response.facet_by_field_name(facet_field)
      limit = @response.facet_by_field_name(facet_field).limit

      if limit.nil? # we didn't get or a set a limit, so infer one.
        facet.limit if facet.limit != true
      elsif limit == -1 # limit -1 is solr-speak for unlimited
        nil
      else
        limit.to_i - 1 # we added 1 to find out if we needed to paginate
      end
    elsif (facet.limit and facet.limit != true)
      facet.limit
    end
  end

  ##
  # The key to use to retrieve the grouped field to display 
  def grouped_key_for_results
    blacklight_config.index.group
  end

  def blacklight_solr
    @solr ||=  RSolr.connect(blacklight_solr_config)
  end

  def blacklight_solr_config
    Blacklight.solr_config
  end

  private

  def should_add_to_solr field_name, field
    field.include_in_request || (field.include_in_request.nil? && blacklight_config.add_field_configuration_to_solr_request)
  end
end
