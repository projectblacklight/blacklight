# frozen_string_literal: true
module Blacklight
  class AbstractRepository
    attr_accessor :blacklight_config
    attr_writer :connection

    # ActiveSupport::Benchmarkable requires a logger method
    attr_accessor :logger

    include ActiveSupport::Benchmarkable

    def initialize blacklight_config
      @blacklight_config = blacklight_config
    end

    def connection
      @connection ||= build_connection
    end

    ##
    # Find a single document result by a known id
    # @param [String] id document's unique key value
    # @param [Hash] params additional query parameters
    def find(_id, _params = {})
      raise NotImplementedError
    end

    ##
    # Execute a search query against a search index
    # @param [Hash] params query parameters
    def search(_params = {})
      raise NotImplementedError
    end

    protected

    def connection_config
      blacklight_config.connection_config
    end

    def logger
      @logger ||= Blacklight.logger
    end
  end
end
