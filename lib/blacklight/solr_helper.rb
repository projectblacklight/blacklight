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

  include Blacklight::RequestBuilders

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

    solr_repository.search(solr_params)
  end

  # a solr query method
  # retrieve a solr document, given the doc id
  # @return [Blacklight::SolrResponse, Blacklight::SolrDocument] the solr response object and the first document
  def get_solr_response_for_doc_id(id, extra_controller_params={})
    solr_response = solr_repository.find id, extra_controller_params
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

    solr_response = query_solr(user_params, extra_controller_params.merge(solr_document_ids_params(ids)))

    [solr_response, solr_response.documents]
  end

  ##
  # Get the solr response when retrieving only a single facet field
  # @return [Blacklight::SolrResponse] the solr response
  def get_facet_field_response(facet_field, user_params = params || {}, extra_controller_params = {})
    solr_params = solr_facet_params(facet_field, user_params, extra_controller_params)
    query_solr(user_params, extra_controller_params.merge(solr_facet_params(facet_field, user_params, extra_controller_params)))
  end

  # Get the previous and next document from a search result
  # @return [Blacklight::SolrResponse, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
  def get_previous_and_next_documents_for_search(index, request_params, extra_controller_params={})

    solr_response = query_solr(request_params, extra_controller_params.merge(previous_and_next_document_params(index)))

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

    response = query_solr(request_params, solr_opensearch_params(field).merge(extra_controller_params))

    [response.params[:q], response.documents.flat_map {|doc| doc[field] }.uniq]
  end

  ##
  # The key to use to retrieve the grouped field to display 
  def grouped_key_for_results
    blacklight_config.index.group
  end

  def solr_repository
    @solr_repository ||= Blacklight::SolrRepository.new(blacklight_config)
  end
end
