# frozen_string_literal: true

module Blacklight
  module SearchContext
    class ServerAppliedParamsComponent < Blacklight::Component
      delegate :current_search_session, :link_back_to_catalog, to: :helpers

      def render?
        current_search_session
      end
    end
  end
end
