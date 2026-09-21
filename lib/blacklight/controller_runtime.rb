# frozen_string_literal: true

module Blacklight
  # Adds Solr timing to the Rails request log line, mirroring how
  # ActiveRecord::Railties::ControllerRuntime adds ActiveRecord timing, e.g.:
  #   Completed 200 OK in 62ms (Views: 12.0ms | ActiveRecord: 1.2ms | Solr: 45.3ms (2 queries))
  module ControllerRuntime
    extend ActiveSupport::Concern

    protected

    def process_action(action, *args)
      Blacklight::RuntimeRegistry.stats.reset
      super
    end

    def append_info_to_payload(payload)
      super
      stats = Blacklight::RuntimeRegistry.stats
      payload[:solr_runtime] = stats.solr_runtime
      payload[:solr_query_count] = stats.solr_query_count
      stats.reset
    end

    module ClassMethods
      def log_process_action(payload)
        messages = super
        count = payload[:solr_query_count].to_i
        return messages unless count.positive?

        messages << solr_log_message(payload[:solr_runtime], count)
        messages
      end

      private

      def solr_log_message(runtime, count)
        format("Solr: %.1fms (%d %s)", runtime.to_f, count, "query".pluralize(count))
      end
    end
  end
end
