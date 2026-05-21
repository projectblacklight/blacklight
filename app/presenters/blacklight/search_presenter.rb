module Blacklight
  class SearchPresenter
    attr_reader :response, :blacklight_config
    delegate_missing_to :response

    def initialize(response:, search_state:, blacklight_config: nil, view_context: nil)
      @response = response
      @search_state = search_state
      @blacklight_config = blacklight_config || response.blacklight_config || search_state.blacklight_config
      @view_context = view_context
    end
  end
end
