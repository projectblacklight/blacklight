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
#     def repository_class
#       MyAlternativeRepo
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
#     def repository_class
#       MyAlternativeRepo
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
    request_params = args.extract_options!
    path = args.first || blacklight_config.solr_path

    request_params[:qt] ||= blacklight_config.qt

    repository.send_and_receive path, request_params
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
    query = search_builder.with(user_params).merge(extra_controller_params)
    response = repository.search(query)

    case
    when (response.grouped? && grouped_key_for_results)
      [response.group(grouped_key_for_results), []]
    when (response.grouped? && response.grouped.length == 1)
      [response.grouped.first, []]
    else
      [response, response.documents]
    end
  end
  deprecation_deprecate get_search_results: :search_results

  # a solr query method
  # @param [Hash,HashWithIndifferentAccess] user_params ({}) the user provided parameters (e.g. query, facets, sort, etc)
  # @param [List<Symbol] processor_chain a list of filter methods to run
  # @yield [search_builder] optional block yields configured SearchBuilder, caller can modify or create new SearchBuilder to be used. Block should return SearchBuilder to be used. 
  # @return [Blacklight::Solr::Response] the solr response object
  def search_results(user_params, search_params_logic)
    builder = search_builder(search_params_logic).with(user_params)
    builder.page(user_params[:page]) if user_params[:page]
    builder.rows(user_params[:per_page] || user_params[:rows]) if user_params[:per_page] or user_params[:rows]

    if block_given? 
      builder = yield(builder)
    end

    response = repository.search(builder)

    case
    when (response.grouped? && grouped_key_for_results)
      [response.group(grouped_key_for_results), []]
    when (response.grouped? && response.grouped.length == 1)
      [response.grouped.first, []]
    else
      [response, response.documents]
    end
  end

  # a solr query method
  # @param [Hash,HashWithIndifferentAccess] user_params ({}) the user provided parameters (e.g. query, facets, sort, etc)
  # @param [Hash,HashWithIndifferentAccess] extra_controller_params ({}) extra parameters to add to the search
  # @return [Blacklight::SolrResponse] the solr response object
  def query_solr(user_params = params || {}, extra_controller_params = {})
    query = search_builder.with(user_params).merge(extra_controller_params)
    repository.search(query)
  end
  deprecation_deprecate :query_solr

  # retrieve a document, given the doc id
  # @return [Blacklight::Solr::Response, Blacklight::SolrDocument] the solr response object and the first document
  def fetch(id=nil, extra_controller_params={})
    if id.is_a? Array
      fetch_many(id, params, extra_controller_params)
    else
      if id.nil?
        Deprecation.warn Blacklight::SearchHelper, "Calling #fetch without an explicit id argument is deprecated and will be removed in Blacklight 6.0"
        id ||= params[:id]
      end
      fetch_one(id, extra_controller_params)
    end
  end

  alias_method :get_solr_response_for_doc_id, :fetch
  deprecation_deprecate get_solr_response_for_doc_id: "use fetch(id) instead"

  # given a field name and array of values, get the matching SOLR documents
  # @return [Blacklight::SolrResponse, Array<Blacklight::SolrDocument>] the solr response object and a list of solr documents
  def get_solr_response_for_field_values(field, values, extra_controller_params = {})
    query = Deprecation.silence(Blacklight::RequestBuilders) do
      search_builder.with(params).merge(extra_controller_params).merge(solr_documents_by_field_values_params(field, values))
    end

    solr_response = repository.search(query)


    [solr_response, solr_response.documents]
  end
  deprecation_deprecate :get_solr_response_for_field_values

  ##
  # Get the solr response when retrieving only a single facet field
  # @return [Blacklight::Solr::Response] the solr response
  def get_facet_field_response(facet_field, user_params = params || {}, extra_controller_params = {})
    query = search_builder.with(user_params).facet(facet_field)
    repository.search(query.merge(extra_controller_params))
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
    Blacklight::Solr::FacetPaginator.new(response.aggregations[facet_field].items,
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
    query = search_builder.with(request_params).start(index - 1).rows(1).merge(fl: "*")
    response = repository.search(query)
    response.documents.first
  end
  deprecation_deprecate :get_single_doc_via_search

  # Get the previous and next document from a search result
  # @return [Blacklight::Solr::Response, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
  def get_previous_and_next_documents_for_search(index, request_params, extra_controller_params={})
    p = previous_and_next_document_params(index)

    query = search_builder.with(request_params).start(p.delete(:start)).rows(p.delete(:rows)).merge(extra_controller_params).merge(p)
    response = repository.search(query)

    document_list = response.documents

    # only get the previous doc if there is one
    prev_doc = document_list.first if index > 0
    next_doc = document_list.last if (index + 1) < response.total

    [response, [prev_doc, next_doc]]
  end
  
  # a solr query method
  # does a standard search but returns a simplified object.
  # an array is returned, the first item is the query string,
  # the second item is an other array. This second array contains
  # all of the field values for each of the documents...
  # where the field is the "field" argument passed in.
  def get_opensearch_response(field=nil, request_params = params || {}, extra_controller_params={})
    field ||= blacklight_config.view_config('opensearch').title_field

    query = search_builder.with(request_params).merge(solr_opensearch_params(field)).merge(extra_controller_params)
    response = repository.search(query)

    [response.params[:q], response.documents.flat_map {|doc| doc[field] }.uniq]
  end

  ##
  # The key to use to retrieve the grouped field to display 
  def grouped_key_for_results
    blacklight_config.index.group
  end

  def repository_class
    blacklight_config.repository_class
  end

  def repository
    @repository ||= repository_class.new(blacklight_config)
  end

  def solr_repository
    repository
  end
  deprecation_deprecate solr_repository: :repository

  def blacklight_solr
    repository.connection
  end
  deprecation_deprecate blacklight_solr: "use repository.connection instead"

  private

    ##
    # Retrieve a set of documents by id
    # @overload fetch_many(ids, extra_controller_params)
    # @overload fetch_many(ids, user_params, extra_controller_params)
    def fetch_many(ids=[], *args)
      if args.length == 1
        Deprecation.warn(Blacklight::SearchHelper, "fetch_many with 2 arguments is deprecated")
        user_params = params
        extra_controller_params = args.first || {}
      else
        user_params, extra_controller_params = args
        user_params ||= params
        extra_controller_params ||= {}
      end

      query = search_builder.
                with(user_params).
                where(blacklight_config.document_model.unique_key => ids).
                merge(extra_controller_params).
                merge(fl: '*')
      solr_response = repository.search(query)

      [solr_response, solr_response.documents]
    end

    alias_method :get_solr_response_for_document_ids, :fetch_many
    deprecation_deprecate get_solr_response_for_document_ids: "use fetch(ids) instead"

    def fetch_one(id, extra_controller_params)
      old_solr_doc_params = Deprecation.silence(Blacklight::SearchHelper) do
        solr_doc_params(id)
      end

      if default_solr_doc_params(id) != old_solr_doc_params
        Deprecation.warn Blacklight::SearchHelper, "The #solr_doc_params method is deprecated. Instead, you should provide a custom SolrRepository implementation for the additional behavior you're offering. The current behavior will be removed in Blacklight 6.0"
        extra_controller_params = extra_controller_params.merge(old_solr_doc_params)
      end

      solr_response = repository.find id, extra_controller_params
      [solr_response, solr_response.documents.first]
    end

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
