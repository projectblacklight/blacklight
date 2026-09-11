# frozen_string_literal: true

module Blacklight
  class RuntimeRegistry
    thread_mattr_accessor :connection, :connection_config

    # per-thread/fiber Solr timing, read by Blacklight::ControllerRuntime
    class Stats
      attr_accessor :solr_runtime, :solr_query_count

      def initialize
        @solr_runtime = 0.0
        @solr_query_count = 0
      end

      public alias_method :reset, :initialize
    end

    class << self
      def stats
        ActiveSupport::IsolatedExecutionState[:blacklight_solr_runtime] ||= Stats.new
      end

      # @see ActiveSupport::Notifications.monotonic_subscribe
      def call(_name, start, finish, _id, _payload)
        stats.solr_runtime += (finish - start) * 1000.0
        stats.solr_query_count += 1
      end
    end
  end
end
