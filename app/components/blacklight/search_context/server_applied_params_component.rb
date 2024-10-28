# frozen_string_literal: true

module Blacklight
  module SearchContext
    # This is displayed on the show page when the user has a search session.
    class ServerAppliedParamsComponent < Blacklight::Component
      delegate :current_search_session, :link_back_to_catalog, to: :helpers

      def render?
        current_search_session
      end

      def start_over
        render start_over_component.new
      end

      def start_over_component
        Blacklight::StartOverButtonComponent
      end
    end
  end
end
