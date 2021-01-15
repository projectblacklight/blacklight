# frozen_string_literal: true

module Blacklight
  module Document
    # Render the thumbnail for the document
    class ThumbnailComponent < ::ViewComponent::Base
      with_collection_parameter :presenter

      # @param [Blacklight::DocumentPresenter] presenter
      # @param [Integer] counter
      # @param [Hash] image_options options for the thumbnail presenter's image tag
      def initialize(presenter:, counter:, image_options: {})
        @presenter = presenter
        @counter = counter
        @image_options = { alt: '' }.merge(image_options)
        @use_thumbnail_tag = !@presenter.thumbnail.instance_of?(Blacklight::ThumbnailPresenter)
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
