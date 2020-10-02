# frozen_string_literal: true
module Blacklight
  # Base class for Blacklight repository adapters
  class AbstractRepository
    # @return [Blacklight::Configuration]
    attr_accessor :blacklight_config

    # Direct writer for the connection
    attr_writer :connection

    # (Note: ActiveSupport::Benchmarkable requires a logger method)
    # @return [Logger]
    attr_writer :logger

    include ActiveSupport::Benchmarkable

    ##
    # @param [Blacklight::Configuration] blacklight_config
    def initialize blacklight_config
      @blacklight_config = blacklight_config
    end

    ##
    # The raw data store connection
    def connection
      @connection ||= build_connection
    end

    ##
    # Find a single document result by a known id
    # @param [String] _id document's unique key value
    # @param [Hash] _params additional query parameters
    def find(_id, _params = {})
      raise NotImplementedError
    end

    ##
    # Execute a search query against a search index
    # @param [Hash] _params query parameters
    def search(_params = {})
      raise NotImplementedError
    end

    # Query the fields that exist from the index
    # @return [Hash]
    def reflect_fields
      raise NotImplementedError
    end

    ##
    # Is the repository in a working state?
    def ping
      raise NotImplementedError
    end

    private

    def connection_config
      blacklight_config.connection_config
    end

    def logger
      @logger ||= Blacklight.logger
    end
  end
end
