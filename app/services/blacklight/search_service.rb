# frozen_string_literal: true

# SearchService returns search results from the repository
module Blacklight
  class SearchService
    # @params [Blacklight::Configuration] config
    # @params [Blacklight::SearchState] search_state
    # @params [Class] search_builder_class a class that inherits from Blacklight::SearchBuilder
    # @params [Hash] context any data the search builder needs to access. For example, the current user.
    def initialize(config:, search_state:, search_builder_class: config.search_builder_class, **context)
      @blacklight_config = config
      @search_state = search_state
      @user_params = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(@search_state.params,
                                                                           'Use @search_state.params instead of @user_params',
                                                                           Blacklight.deprecation)
      @search_builder_class = search_builder_class
      @context = context
    end

    # The blacklight_config + controller are accessed by the search_builder
    attr_reader :blacklight_config, :context

    def search_builder
      search_builder_class.new(self, blacklight_config: blacklight_config)
    end

    # Fetch query results from solr
    # @yield [search_builder] optional block yields configured SearchBuilder,  caller can modify or create new
    #                         SearchBuilder to be used. Block should return SearchBuilder to be used.
    #                         This is used in blacklight_range_limit
    # @return [Blacklight::Solr::Response] the solr response object
    def search_results
      builder = search_builder.with(search_state)
      builder.page = search_state.page
      builder.rows = search_state.per_page

      builder = yield(builder) if block_given?
      response = repository.search(params: builder)

      if response.grouped? && grouped_key_for_results
        response.group(grouped_key_for_results)
      elsif response.grouped? && response.grouped.length == 1
        response.grouped.first
      else
        response
      end
    end

    # retrieve a document, given the doc id
    # @param [Array{#to_s},#to_s] id
    # @return [Blacklight::SolrDocument] the solr document (or array of
    #   documents if an array of ids was given)
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
      repository.search(params: query.merge(extra_controller_params))
    end

    def facet_suggest_response(facet_field, facet_suggestion_query, extra_controller_params = {})
      query = search_builder.with(search_state).facet(facet_field).facet_suggestion_query(facet_suggestion_query)
      repository.search(params: query.merge(extra_controller_params))
    end

    # Get the previous and next document from a search result
    # @return [Blacklight::Solr::Response, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
    def previous_and_next_documents_for_search(index, request_params, params: nil, **extra_controller_params)
      unless params
        new_state = request_params.is_a?(Blacklight::SearchState) ? request_params : Blacklight::SearchState.new(request_params, blacklight_config)
        builder = search_builder.with(new_state)

        search_service_params = Blacklight.deprecation.silence do
          previous_and_next_document_params(index)
        end

        builder = if search_service_params.empty?
                    builder.for_previous_and_next_documents(index).merge(extra_controller_params)
                  else
                    Blacklight.deprecation.warn("SearchService#previous_and_next_document_params returned parameters. Implement customizations in SearchBuilder#for_previous_and_next_document instead")
                    builder.start(search_service_params.delete(:start)).rows(search_service_params.delete(:rows)).merge(extra_controller_params).merge(search_service_params)
                  end
      end

      response = repository.search(params: params || builder)
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
    # @deprecated
    def opensearch_response(field = nil, extra_controller_params = {})
      field ||= blacklight_config.view_config(:opensearch).title_field

      query = search_builder.with(search_state).merge(solr_opensearch_params(field)).merge(extra_controller_params)
      response = repository.search(params: query)

      [search_state.query_param, response.documents.flat_map { |doc| doc[field] }.uniq]
    end
    Blacklight.deprecation.deprecate_methods Blacklight::SearchService, opensearch_response: "The opensearch_response method is deprecated without replacement."

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
    # @deprecated
    def solr_opensearch_params(field)
      solr_params = {}
      solr_params[:rows] ||= 10
      solr_params[:fl] = field || blacklight_config.view_config(:opensearch).title_field
      solr_params
    end
    Blacklight.deprecation.deprecate_methods Blacklight::SearchService, solr_opensearch_params: "The solr_opensearch_params method is deprecated without replacement."

    def previous_and_next_document_params(*, **)
      {}
    end
    Blacklight.deprecation.deprecate_methods(Blacklight::SearchService,
                                             previous_and_next_document_params: "Use SearchBuilder#for_previous_and_next_documents instead of SearchService#previous_and_next_document_params")

    ##
    # Retrieve a set of documents by id
    # @param [Array] ids
    # @param [HashWithIndifferentAccess] extra_controller_params
    def fetch_many(ids, extra_controller_params)
      extra_controller_params ||= {}

      requested_rows = extra_controller_params.delete(:rows)
      if requested_rows
        Blacklight.deprecation.warn("Passing :rows to fetch_many is deprecated. Create an issue in blacklight if you see this warning. " \
                                    "Otherwise, :rows will be ignored in Blackight 10")
      else
        requested_rows = ids.count
      end

      query = search_builder
              .with(search_state)
              .where(blacklight_config.document_model.unique_key => ids)
              .merge(blacklight_config.fetch_many_document_params)
              .merge(extra_controller_params)
      query.rows(requested_rows)

      # find_many was introduced in Blacklight 8.4. Before that, we used the
      # regular search method (possibly with a find-many specific `qt` parameter).
      # In order to support Repository implementations that may not have a find_many,
      # we'll fall back to search if find_many isn't available.
      solr_response = if repository.respond_to?(:find_many)
                        repository.find_many(query)
                      else
                        Blacklight.deprecation.warn("Repository#find_many is not implemented. Falling back to Repository#search.")
                        repository.search(params: query)
                      end

      solr_response.documents
    end

    def fetch_one(id, extra_controller_params)
      solr_response = repository.find id, extra_controller_params
      solr_response.documents.first
    end
  end
end
