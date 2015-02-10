# -*- encoding : utf-8 -*-
# SearchHelper is a controller layer mixin. It is in the controller scope: request params, session etc.
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
#     def search_params
#       super.merge :per_page=>10
#     end
#   end
#
# Or by including in local extensions:
#   module LocalSearchHelperExtension
#     [ local overrides ]
#   end
#
#   class CatalogController < ActionController::Base
#
#     include Blacklight::Catalog
#     include LocalSearchHelperExtension
#
#     def search_params
#       super.merge :per_page=>10
#     end
#   end
#
# Or by using ActiveSupport::Concern:
#
#   module LocalSearchHelperExtension
#     extend ActiveSupport::Concern
#     include Blacklight::SearchHelper
#
#     [ local overrides ]
#   end
#
#   class CatalogController < ApplicationController
#     include LocalSearchHelperExtension
#     include Blacklight::Catalog
#   end

module Blacklight::SearchHelper
  extend ActiveSupport::Concern
  extend Deprecation
  self.deprecation_horizon = 'blacklight 6.0'

  include Blacklight::RequestBuilders

  ##
  # Execute a solr query
  # @see [Blacklight::SolrRepository#send_and_receive]
  # @return [Blacklight::SolrResponse] the solr response object
  def find *args
    solr_params = args.extract_options!
    path = args.first || blacklight_config.solr_path

    solr_params[:qt] ||= blacklight_config.qt

    repository.send_and_receive path, solr_params
  end
  deprecation_deprecate :find

  # returns a params hash for finding a single solr document (CatalogController #show action)
  def solr_doc_params(id=nil)
    default_solr_doc_params(id)
  end
  deprecation_deprecate :solr_doc_params

  # a solr query method
  # given a user query, return a solr response containing both result docs and facets
  # - mixes in the Blacklight::Solr::SpellingSuggestions module
  #   - the response will have a spelling_suggestions method
  # Returns a two-element array (aka duple) with first the solr response object,
  # and second an array of SolrDocuments representing the response.docs
  def get_search_results(user_params = params || {}, extra_controller_params = {})
    solr_response = query_repository(user_params, extra_controller_params)

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
    query_repository(user_params, extra_controller_params)
  end
  deprecation_deprecate :query_solr

  # given a user query,
  # @return [Blacklight::SolrResponse] the solr response object
  def query_repository(user_params = params || {}, extra_controller_params = {})
    solr_params = self.search_params(user_params).merge(extra_controller_params)

    repository.search(solr_params)
  end

  # a solr query method
  # retrieve a solr document, given the doc id
  # @return [Blacklight::SolrResponse, Blacklight::SolrDocument] the solr response object and the first document
  def get_solr_response_for_doc_id(id=nil, extra_controller_params={})
    if id.nil?
      Deprecation.warn Blacklight::SearchHelper, "Calling #get_solr_response_for_doc_id without an explicit id argument is deprecated"
      id ||= params[:id]
    end

    old_solr_doc_params = Deprecation.silence(Blacklight::SearchHelper) do
      solr_doc_params(id)
    end

    if default_solr_doc_params(id) != old_solr_doc_params
      Deprecation.warn Blacklight::SearchHelper, "The #solr_doc_params method is deprecated. Instead, you should provide a custom SolrRepository implementation for the additional behavior you're offering"
      extra_controller_params = extra_controller_params.merge(old_solr_doc_params)
    end

    solr_response = repository.find id, extra_controller_params
    [solr_response, solr_response.documents.first]
  end
  
  ##
  # Retrieve a set of documents by id
  # @overload get_solr_response_for_document_ids(ids, extra_controller_params)
  # @overload get_solr_response_for_document_ids(ids, user_params, extra_controller_params)
  def get_solr_response_for_document_ids(ids=[], *args)
    # user_params = params || {}, extra_controller_params = {}
    if args.length == 1
      user_params = params
      extra_controller_params = args.first || {}
    else
      user_params, extra_controller_params = args
      user_params ||= params
      extra_controller_params ||= {}
    end

    solr_response = query_repository(user_params, extra_controller_params.merge(solr_document_ids_params(ids)))

    [solr_response, solr_response.documents]
  end

  # given a field name and array of values, get the matching SOLR documents
  # @return [Blacklight::SolrResponse, Array<Blacklight::SolrDocument>] the solr response object and a list of solr documents
  def get_solr_response_for_field_values(field, values, extra_controller_params = {})
    solr_response = query_repository(params, extra_controller_params.merge(solr_documents_by_field_values_params(field, values)))

    [solr_response, solr_response.documents]
  end
  deprecation_deprecate :get_solr_response_for_field_values

  ##
  # Get the solr response when retrieving only a single facet field
  # @return [Blacklight::SolrResponse] the solr response
  def get_facet_field_response(facet_field, user_params = params || {}, extra_controller_params = {})
    solr_params = solr_facet_params(facet_field, user_params, extra_controller_params)
    query_repository(user_params, extra_controller_params.merge(solr_facet_params(facet_field, user_params, extra_controller_params)))
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
    solr_params = search_params(request_params)

    solr_params[:start] = (index - 1) # start at 0 to get 1st doc, 1 to get 2nd.
    solr_params[:rows] = 1
    solr_params[:fl] = '*'
    solr_response = repository.search(solr_params)
    solr_response.documents.first
  end
  deprecation_deprecate :get_single_doc_via_search

  # Get the previous and next document from a search result
  # @return [Blacklight::SolrResponse, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
  def get_previous_and_next_documents_for_search(index, request_params, extra_controller_params={})

    solr_response = query_repository(request_params, extra_controller_params.merge(previous_and_next_document_params(index)))

    document_list = solr_response.documents

    # only get the previous doc if there is one
    prev_doc = document_list.first if index > 0
    next_doc = document_list.last if (index + 1) < solr_response.total

    [solr_response, [prev_doc, next_doc]]
  end
  
  # a solr query method
  # does a standard search but returns a simplified object.
  # an array is returned, the first item is the query string,
  # the second item is an other array. This second array contains
  # all of the field values for each of the documents...
  # where the field is the "field" argument passed in.
  def get_opensearch_response(field=nil, request_params = params || {}, extra_controller_params={})
    field ||= blacklight_config.view_config('opensearch').title_field

    response = query_repository(request_params, solr_opensearch_params(field).merge(extra_controller_params))

    [response.params[:q], response.documents.flat_map {|doc| doc[field] }.uniq]
  end

  ##
  # The key to use to retrieve the grouped field to display 
  def grouped_key_for_results
    blacklight_config.index.group
  end

  def repository_class
    Blacklight::SolrRepository
  end

  def repository
    @repository ||= repository_class.new(blacklight_config)
  end

  def solr_repository
    repository
  end
  deprecation_deprecate :solr_repository

  def blacklight_solr
    repository.blacklight_solr
  end
  deprecation_deprecate :blacklight_solr

  private

  ##
  # @deprecated
  def default_solr_doc_params(id=nil)
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

end
