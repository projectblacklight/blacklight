# frozen_string_literal: true

module Blacklight
  module Document
    # Render the thumbnail for the document
    class ThumbnailComponent < ::ViewComponent::Base
      with_collection_parameter :presenter

      # @param [Blacklight::DocumentPresenter] presenter
      def initialize(presenter:, counter:)
        @presenter = presenter
        @counter = counter
      end

      def render?
        @presenter.thumbnail.exists?
      end
    end
  end
end
