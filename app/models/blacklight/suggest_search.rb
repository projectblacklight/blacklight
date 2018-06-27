# frozen_string_literal: true

module Blacklight
  class SuggestSearch
    attr_reader :request_params, :repository

    ##
    # @param [Hash] params
    # @param [Blacklight::AbstractRepository] repository
    def initialize(params, repository)
      @request_params = { q: params[:q] }
      @repository = repository
    end

    ##
    # For now, only use the q parameter to create a
    # Blacklight::Suggest::Response
    # @return [Blacklight::Suggest::Response]
    def suggestions
      repository.suggestions(request_params)
    end
  end
end
