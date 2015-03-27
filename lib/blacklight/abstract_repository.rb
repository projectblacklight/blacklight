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

    protected
      def connection_config
        blacklight_config.connection_config
      end

      def logger
        @logger ||= Blacklight.logger
      end
  end
end
