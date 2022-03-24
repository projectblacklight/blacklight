# frozen_string_literal: true

module Blacklight
  class StartOverButtonComponent < Blacklight::Component
    def call
      link_to t('blacklight.search.start_over'), start_over_path, class: 'catalog_startOverLink btn btn-primary'
    end

    private

    ##
    # Get the path to the search action with any parameters (e.g. view type)
    # that should be persisted across search sessions.
    def start_over_path query_params = params
      h = {}
      current_index_view_type = helpers.document_index_view_type(query_params)
      h[:view] = current_index_view_type unless current_index_view_type == helpers.default_document_index_view_type

      helpers.search_action_path(h)
    end
  end
end
