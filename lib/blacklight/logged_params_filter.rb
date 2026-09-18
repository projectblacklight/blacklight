# frozen_string_literal: true

module Blacklight
  # Prepares the Solr parameters of a solr_request.blacklight notification for the debug log.
  #
  # Parameters can contain very large values, notably the query vector of a dense
  # vector (KNN) search, which serializes to a string of hundreds of floats and
  # buries the rest of the request, so values longer than max_value_length are
  # replaced with a placeholder.
  #
  # Swap in different behavior with anything that responds to #call:
  #
  #   Blacklight::LogSubscriber.params_filter = Blacklight::LoggedParamsFilter.new(max_value_length: 1_000)
  #   Blacklight::LogSubscriber.params_filter = ->(params) { params.except(:json) }
  class LoggedParamsFilter
    # @param [Integer, nil] max_value_length values longer than this are replaced;
    #   nil logs every value in full.
    def initialize(max_value_length: 200)
      @max_value_length = max_value_length
    end

    attr_reader :max_value_length

    # @param [Hash] params the Solr request parameters
    # @return [Hash] a copy of the parameters with over-long values replaced
    def call(params)
      filter(params)
    end

    private

    def filter(value)
      case value
      when Hash then value.transform_values { |v| filter(v) }
      when Array then value.map { |v| filter(v) }
      when String then filter_string(value)
      else value
      end
    end

    def filter_string(value)
      return value if max_value_length.blank? || value.length <= max_value_length

      "OMITTED (#{value.length} characters)"
    end
  end
end
