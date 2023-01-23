# frozen_string_literal: true

module Blacklight
  module SearchContext
    class ClientAppliedParamsComponent < Blacklight::Component
      delegate :search_action_path, to: :helpers
      def render?
        controller.params[:counter]
      end
    end
  end
end
