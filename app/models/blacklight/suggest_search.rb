# frozen_string_literal: true
module Blacklight
  class SuggestSearch
    attr_reader :request_params, :repository

    ##
    # @param [Hash] params
    def initialize(params, repository)
      @request_params = { q: params[:q] }
      @repository = repository
    end

    ##
    # For now, only use the q parameter to create a
    # Blacklight::Suggest::Response
    # @return [Blacklight::Suggest::Response]
    def suggestions
      Blacklight::Suggest::Response.new suggest_results, request_params, suggest_handler_path
    end

    ##
    # Query the suggest handler using RSolr::Client::send_and_receive
    # @return [RSolr::HashWithResponse]
    def suggest_results
      repository.connection.send_and_receive(suggest_handler_path, params: request_params)
    end

    ##
    # @return [String]
    def suggest_handler_path
      repository.blacklight_config.autocomplete_path
    end
  end
end
