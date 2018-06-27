# frozen_string_literal: true
module Blacklight::Solr
  class Repository < Blacklight::AbstractRepository
    ##
    # Find a single solr document result (by id) using the document configuration
    # @param [String] id document's unique key value
    # @param [Hash] params additional solr query parameters
    def find id, params = {}
      doc_params = params.reverse_merge(blacklight_config.default_document_solr_params)
                         .reverse_merge(qt: blacklight_config.document_solr_request_handler)
                         .merge(blacklight_config.document_unique_id_param => id)

      solr_response = send_and_receive blacklight_config.document_solr_path || blacklight_config.solr_path, doc_params
      raise Blacklight::Exceptions::RecordNotFound if solr_response.documents.empty?
      solr_response
    end

    ##
    # Execute a search query against solr
    # @param [Hash] params solr query parameters
    def search params = {}
      send_and_receive blacklight_config.solr_path, params.reverse_merge(qt: blacklight_config.qt)
    end

    # @param [Hash] params
    # @return [Blacklight::Suggest::Response]
    def suggestions(request_params)
      suggest_results = connection.send_and_receive(suggest_handler_path, params: request_params)
      Blacklight::Suggest::Response.new suggest_results, request_params, suggest_handler_path
    end

    ##
    # Gets a list of available fields
    # @return [Hash]
    def reflect_fields
      send_and_receive('admin/luke', params: { fl: '*', 'json.nl' => 'map' })['fields']
    end

    ##
    # @return [boolean] true if the repository is reachable
    def ping
      response = connection.send_and_receive 'admin/ping', {}
      Blacklight.logger.info("Ping [#{connection.uri}] returned: '#{response['status']}'")
      response['status'] == "OK"
    end

    ##
    # Execute a solr query
    # TODO: Make this private after we have a way to abstract admin/luke and ping
    # @see [RSolr::Client#send_and_receive]
    # @overload find(solr_path, params)
    #   Execute a solr query at the given path with the parameters
    #   @param [String] solr path (defaults to blacklight_config.solr_path)
    #   @param [Hash] parameters for RSolr::Client#send_and_receive
    # @overload find(params)
    #   @param [Hash] parameters for RSolr::Client#send_and_receive
    # @return [Blacklight::Solr::Response] the solr response object
    def send_and_receive(path, solr_params = {})
      benchmark("Solr fetch", level: :debug) do
        key = blacklight_config.http_method == :post ? :data : :params
        res = connection.send_and_receive(path, { key => solr_params.to_hash, method: blacklight_config.http_method })

        solr_response = blacklight_config.response_model.new(res, solr_params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)

        Blacklight.logger.debug("Solr query: #{blacklight_config.http_method} #{path} #{solr_params.to_hash.inspect}")
        Blacklight.logger.debug("Solr response: #{solr_response.inspect}") if defined?(::BLACKLIGHT_VERBOSE_LOGGING) && ::BLACKLIGHT_VERBOSE_LOGGING
        solr_response
      end
    rescue Errno::ECONNREFUSED => e
      raise Blacklight::Exceptions::ECONNREFUSED, "Unable to connect to Solr instance using #{connection.inspect}: #{e.inspect}"
    rescue RSolr::Error::Http => e
      raise Blacklight::Exceptions::InvalidRequest, e.message
    end

    private

    ##
    # @return [String]
    def suggest_handler_path
      blacklight_config.autocomplete_path
    end

    def build_connection
      RSolr.connect(connection_config.merge(adapter: connection_config[:http_adapter]))
    end
  end
end
