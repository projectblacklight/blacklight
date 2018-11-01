# frozen_string_literal: true
module Blacklight
  module Suggest
    class Response
      attr_reader :response, :request_params, :suggest_path, :suggester_name

      ##
      # Creates a suggest response
      # @param [RSolr::HashWithResponse] response
      # @param [Hash] request_params
      # @param [String] suggest_path
      # @param [String] suggester_name
      def initialize(response, request_params, suggest_path, suggester_name)
        @response = response
        @request_params = request_params
        @suggest_path = suggest_path
        @suggester_name = suggester_name
      end

      ##
      # Trys the suggestor response to return suggestions if they are
      # present
      # @return [Array]
      def suggestions
        (response.try(:[], suggest_path).try(:[], suggester_name).try(:[], request_params[:q]).try(:[], 'suggestions') || []).uniq
      end
    end
  end
end
