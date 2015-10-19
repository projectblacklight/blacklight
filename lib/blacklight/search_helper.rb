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
  include Blacklight::RequestBuilders

  # a solr query method
  # @param [Hash,HashWithIndifferentAccess] user_params ({}) the user provided parameters (e.g. query, facets, sort, etc)
  # @param [List<Symbol] processor_chain a list of filter methods to run
  # @yield [search_builder] optional block yields configured SearchBuilder, caller can modify or create new SearchBuilder to be used. Block should return SearchBuilder to be used. 
  # @return [Blacklight::SolrResponse] the solr response object
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

  # retrieve a document, given the doc id
  # @return [Blacklight::SolrResponse, Blacklight::SolrDocument] the solr response object and the first document
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

  ##
  # Get the solr response when retrieving only a single facet field
  # @return [Blacklight::SolrResponse] the solr response
  def get_facet_field_response(facet_field, user_params = params || {}, extra_controller_params = {})
    query = search_builder.with(user_params).facet(facet_field)
    extra_controller_params.merge!({:"facet.prefix"=>user_params[:"facet.prefix"]}) unless user_params[:"facet.prefix"].blank?
    repository.search(query.merge(extra_controller_params))
  end

  # Get the previous and next document from a search result
  # @return [Blacklight::SolrResponse, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
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

  private

    ##
    # Retrieve a set of documents by id
    # @param [Array] ids
    # @param [HashWithIndifferentAccess] user_params
    # @param [HashWithIndifferentAccess] extra_controller_params
    def fetch_many(ids, user_params, extra_controller_params)
      user_params ||= params
      extra_controller_params ||= {}

      query = search_builder.
                with(user_params).
                where(blacklight_config.document_model.unique_key => ids).
                merge(extra_controller_params).
                merge(fl: '*')
      solr_response = repository.search(query)

      [solr_response, solr_response.documents]
    end

    def fetch_one(id, extra_controller_params)
      solr_response = repository.find id, extra_controller_params
      [solr_response, solr_response.documents.first]
    end
end
