# frozen_string_literal: true
# SearchService returns search results from the repository
module Blacklight
  class SearchService
    def initialize(config:, search_state: nil, user_params: nil, search_builder_class: config.search_builder_class, **context)
      @blacklight_config = config
      @search_state = search_state || Blacklight::SearchState.new(user_params || {}, config)
      @user_params = @search_state.params
      @search_builder_class = search_builder_class
      @context = context
    end

    # The blacklight_config + controller are accessed by the search_builder
    attr_reader :blacklight_config, :context

    def search_builder
      search_builder_class.new(self)
    end

    # a solr query method
    # @yield [search_builder] optional block yields configured SearchBuilder, caller can modify or create new SearchBuilder to be used. Block should return SearchBuilder to be used.
    # @return [Blacklight::Solr::Response] the solr response object
    def search_results
      builder = search_builder.with(search_state)
      builder.page = search_state.page
      builder.rows = search_state.per_page

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
      query = search_builder.with(search_state).facet(facet_field)
      repository.search(query.merge(extra_controller_params))
    end

    # Get the previous and next document from a search result
    # @return [Blacklight::Solr::Response, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
    def previous_and_next_documents_for_search(index, request_params, extra_controller_params = {})
      p = previous_and_next_document_params(index)
      new_state = request_params.is_a?(Blacklight::SearchState) ? request_params : Blacklight::SearchState.new(request_params, blacklight_config)
      query = search_builder.with(new_state).start(p.delete(:start)).rows(p.delete(:rows)).merge(extra_controller_params).merge(p)
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

      query = search_builder.with(search_state).merge(solr_opensearch_params(field)).merge(extra_controller_params)
      response = repository.search(query)

      [search_state.query_param, response.documents.flat_map { |doc| doc[field] }.uniq]
    end

    private

    attr_reader :search_builder_class, :user_params, :search_state

    delegate :repository, to: :blacklight_config

    ##
    # The key to use to retrieve the grouped field to display
    def grouped_key_for_results
      blacklight_config.view_config(action_name: :index).group
    end

    ##
    # Opensearch autocomplete parameters for plucking a field's value from the results
    def solr_opensearch_params(field)
      solr_params = {}
      solr_params[:rows] ||= 10
      solr_params[:fl] = field || blacklight_config.view_config(:opensearch).title_field
      solr_params
    end

    ##
    # Pagination parameters for selecting the previous and next documents
    # out of a result set.
    def previous_and_next_document_params(index, window = 1)
      solr_params = blacklight_config.document_pagination_params.dup

      if solr_params.empty?
        solr_params[:fl] = blacklight_config.document_model.unique_key
      end

      if index > 0
        solr_params[:start] = index - window # get one before
        solr_params[:rows] = 2 * window + 1 # and one after
      else
        solr_params[:start] = 0 # there is no previous doc
        solr_params[:rows] = 2 * window # but there should be one after
      end

      solr_params[:facet] = false
      solr_params
    end

    ##
    # Retrieve a set of documents by id
    # @param [Array] ids
    # @param [HashWithIndifferentAccess] extra_controller_params
    def fetch_many(ids, extra_controller_params)
      extra_controller_params ||= {}

      query = search_builder
              .with(search_state)
              .where(blacklight_config.document_model.unique_key => ids)
              .merge(blacklight_config.fetch_many_document_params)
              .merge(extra_controller_params)

      solr_response = repository.search(query)

      [solr_response, solr_response.documents]
    end

    def fetch_one(id, extra_controller_params)
      solr_response = repository.find id, extra_controller_params
      [solr_response, solr_response.documents.first]
    end
  end
end
