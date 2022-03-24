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
      Deprecation.silence(Blacklight::UrlHelperBehavior) do
        helpers.start_over_path(query_params)
      end
    end
  end
end
