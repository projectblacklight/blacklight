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
      # Trys the suggester response to return suggestions if they are
      # present
      # @return [Array]
      def suggestions
        (response.dig(suggest_path, suggester_name, request_params[:q], 'suggestions') || []).uniq
      end
    end
  end
end
