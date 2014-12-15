module Blacklight
  class SolrRepository
    attr_accessor :blacklight_config, :blacklight_solr

    # ActiveSupport::Benchmarkable requires a logger method
    attr_accessor :logger

    include ActiveSupport::Benchmarkable

    def initialize blacklight_config
      @blacklight_config = blacklight_config
    end

    ##
    # Find a single solr document result (by id) using the document configuration
    # @param [String] document's unique key value
    # @param [Hash] additional solr query parameters
    def find id, params = {}
      solr_response = send_and_receive blacklight_config.document_solr_path || blacklight_config.solr_path, {qt: blacklight_config.document_solr_request_handler}.merge(blacklight_config.default_document_solr_params.merge(params).merge(blacklight_config.document_unique_id_param => id))
      raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.documents.empty?
      solr_response
    end

    ##
    # Execute a search query against solr
    # @param [Hash] solr query parameters
    def search params = {}
      send_and_receive blacklight_config.solr_path, params.reverse_merge({ qt: blacklight_config.qt })
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
    def send_and_receive(path, solr_params = {})
      benchmark("Solr fetch", level: :debug) do
        key = blacklight_config.http_method == :post ? :data : :params
        res = blacklight_solr.send_and_receive(path, {key=>solr_params.to_hash, method:blacklight_config.http_method})

        solr_response = blacklight_config.solr_response_model.new(res, solr_params, solr_document_model: blacklight_config.solr_document_model)

        Rails.logger.debug("Solr query: #{solr_params.inspect}")
        Rails.logger.debug("Solr response: #{solr_response.inspect}") if defined?(::BLACKLIGHT_VERBOSE_LOGGING) and ::BLACKLIGHT_VERBOSE_LOGGING
        solr_response
      end
    rescue Errno::ECONNREFUSED => e
      raise Blacklight::Exceptions::ECONNREFUSED.new("Unable to connect to Solr instance using #{blacklight_solr.inspect}")
    end

    def blacklight_solr
      @blacklight_solr ||= RSolr.connect(blacklight_solr_config)
    end

    protected
    def blacklight_solr_config
      @blacklight_solr_config ||= Blacklight.solr_config
    end

    def logger
      @logger ||= Rails.logger if defined? Rails
    end
  end
end
