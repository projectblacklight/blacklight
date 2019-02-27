# frozen_string_literal: true
module Blacklight::Searchable
  # @return [Blacklight::SearchService]
  def search_service
    search_service_class.new(config: blacklight_config, user_params: search_state.to_h, **search_service_context)
  end

  # @return [Hash] a hash of context information to pass through to the search service
  def search_service_context
    {}
  end

  # @return [Blacklight::SuggestSearch]
  def suggestions_service
    Blacklight::SuggestSearch.new(params, search_service.repository).suggestions
  end
end
