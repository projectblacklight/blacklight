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
        @use_thumbnail_tag = @presenter.thumbnail != Blacklight::ThumbnailPresenter
      end

      def render?
        @presenter.thumbnail.exists?
      end

      def warn_about_deprecated_behavior
        Deprecation.warn(Blacklight::Document::ThumbnailComponent, 'Detected as custom thumbnail presenter; make sure it has a #render method that returns just the thumbnail image tag')
      end
    end
  end
end
