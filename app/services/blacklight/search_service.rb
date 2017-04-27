# frozen_string_literal: true

# SearchService returns search results from the repository
module Blacklight
  class SearchService
    include Blacklight::RequestBuilders

    def initialize(blacklight_config, user_params = {})
      @blacklight_config = blacklight_config
      @user_params = user_params
    end

    # TODO: Can this be private?
    attr_reader :blacklight_config

    # a solr query method
    # @param [Hash] user_params ({}) the user provided parameters (e.g. query, facets, sort, etc)
    # @yield [search_builder] optional block yields configured SearchBuilder, caller can modify or create new SearchBuilder to be used. Block should return SearchBuilder to be used.
    # @return [Blacklight::Solr::Response] the solr response object
    def search_results
      builder = search_builder.with(user_params)
      builder.page = user_params[:page] if user_params[:page]
      builder.rows = (user_params[:per_page] || user_params[:rows]) if user_params[:per_page] || user_params[:rows]

      builder = yield(builder) if block_given?
      response = repository.search(builder)

      if response.grouped? && grouped_key_for_results
        [response.group(grouped_key_for_results), []]
      elsif response.grouped? && response.grouped.length == 1
        [response.grouped.first, []]
      else
        [response, response.documents]
      end
    end

    # retrieve a document, given the doc id
    # @param [Array{#to_s},#to_s] id
    # @return [Blacklight::Solr::Response, Blacklight::SolrDocument] the solr response object and the first document
    def fetch(id = nil, extra_controller_params = {})
      if id.is_a? Array
        fetch_many(id, extra_controller_params)
      else
        fetch_one(id, extra_controller_params)
      end
    end

    ##
    # Get the solr response when retrieving only a single facet field
    # @return [Blacklight::Solr::Response] the solr response
    def facet_field_response(facet_field, extra_controller_params = {})
      query = search_builder.with(user_params).facet(facet_field)
      repository.search(query.merge(extra_controller_params))
    end

    # Get the previous and next document from a search result
    # @return [Blacklight::Solr::Response, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
    def previous_and_next_documents_for_search(index, request_params, extra_controller_params = {})
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
    def opensearch_response(field = nil, extra_controller_params = {})
      field ||= blacklight_config.view_config(:opensearch).title_field

      query = search_builder.with(user_params).merge(solr_opensearch_params(field)).merge(extra_controller_params)
      response = repository.search(query)

      [response.params[:q], response.documents.flat_map { |doc| doc[field] }.uniq]
    end

    ##
    # The key to use to retrieve the grouped field to display
    def grouped_key_for_results
      blacklight_config.index.group
    end

    delegate :repository, to: :blacklight_config

    private

    attr_reader :user_params

    ##
    # Retrieve a set of documents by id
    # @param [Array] ids
    # @param [HashWithIndifferentAccess] extra_controller_params
    def fetch_many(ids, extra_controller_params)
      extra_controller_params ||= {}

      query = search_builder
              .with(user_params)
              .where(blacklight_config.document_model.unique_key => ids)
              .merge(extra_controller_params)
              .merge(fl: '*')
      solr_response = repository.search(query)

      [solr_response, solr_response.documents]
    end

    def fetch_one(id, extra_controller_params)
      solr_response = repository.find id, extra_controller_params
      [solr_response, solr_response.documents.first]
    end
  end
end
