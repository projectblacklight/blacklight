# frozen_string_literal: true

module Blacklight
  # Debug-only logging for solr_request.blacklight notifications
  # see Blacklight::ControllerRuntime for the :info-level per-request summary.
  class LogSubscriber < ActiveSupport::LogSubscriber
    # ActiveSupport::LogSubscriber#debug/#info call the instance method
    # `logger`, which the base class hardcodes to `LogSubscriber.logger`
    # (itself) rather than `self.class.logger`. If that's ever fixed
    # upstream, a `self.logger` override here would be worth implementing.
    delegate :logger, to: :Blacklight

    def solr_request(event)
      payload = event.payload
      debug { "Solr fetch (#{event.duration.round(1)}ms): #{payload[:method]} #{payload[:path]} #{payload[:params].to_hash.inspect}" }
      debug { "Solr response: #{payload[:response].inspect}" } if verbose_logging?
    end

    private

    def verbose_logging?
      defined?(::BLACKLIGHT_VERBOSE_LOGGING) && ::BLACKLIGHT_VERBOSE_LOGGING
    end
  end
end
