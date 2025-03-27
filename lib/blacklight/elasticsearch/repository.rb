# frozen_string_literal: true

module Blacklight::Elasticsearch
  class Repository < Blacklight::AbstractRepository
    ##
    # Find a single solr document result (by id) using the document configuration
    # @param [String] id document's unique key value
    # @param [Hash] params additional query parameters
    def find id, params = {}
      api_response = connection.get(index:, id:)
      blacklight_config.response_model.new(api_response, params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)
    rescue Elastic::Transport::Transport::Errors::NotFound
      raise Blacklight::Exceptions::RecordNotFound
    end

    # Find multiple documents by their ids
    # @param [SearchBuilder] search_builder the search builder
    def find_many(search_builder)
      # TODO: This is hacky, but SearchBuilder#where is currently very coupled to Solr
      ids = search_builder.search_state.params['q']['id']
      docs = ids.map { |id| { _index: index, _id: id } }

      api_response = connection.mget(body: { docs: })
      blacklight_config.response_model.new(api_response, search_builder, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)
    end

    ##
    # Execute a search query against solr
    # @param [SearchBuilder] params the search builder
    def search params: nil, **kwargs
      request_params = params.reverse_merge(kwargs)
      api_response = connection.search(index:, body: request_params)
      blacklight_config.response_model.new(api_response, params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)
    end

    def seed_index docs
      begin
        connection.indices.delete(index:)
      rescue StandardError
        Elastic::Transport::Transport::Errors::NotFound
      end

      # TODO: move this to a yaml file
      connection.indices.create index:, body: {
        mappings: {
          properties: {
            format: { type: 'keyword' },
            pub_date_ssim: { type: 'integer' },
            subject_ssim: { type: 'keyword' },
            language_ssim: { type: 'keyword' },
            lc_1letter_ssim: { type: 'keyword' },
            subject_geo_ssim: { type: 'keyword' },
            subject_era_ssim: { type: 'keyword' }
          }
        }
      }

      body = docs.map { |data| { index: { _index: index, _id: data['id'], data: data.except('id') } } }
      connection.bulk(body:)
      connection.indices.refresh(index:)
    end

    # @param [Hash] request_params
    # @return [Blacklight::Suggest::Response]
    def suggestions(request_params)
      suggest_results = {} # TODO: implement
      Blacklight.logger.warn("suggestions has not yet been implemented for elasticsearch")
      Blacklight::Suggest::Response.new suggest_results, request_params, '', ''
    end

    private

    def index
      @index ||= connection_config.fetch(:index)
    end

    # See https://www.elastic.co/guide/en/elasticsearch/client/ruby-api/current/connecting.html
    def build_connection
      ::Elasticsearch::Client.new(url: connection_config[:url])
      # cloud_id: '<CloudID>',
      # user: '<Username>',
      # password: '<Password>'
    end
  end
end
