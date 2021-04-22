# frozen_string_literal: true

module Blacklight
  module Document
    # Render the thumbnail for the document
    class ThumbnailComponent < ::ViewComponent::Base
      with_collection_parameter :presenter

      # @param [Blacklight::DocumentPresenter] presenter
      # @param [Integer] counter
      # @param [Hash] image_options options for the thumbnail presenter's image tag
      def initialize(presenter: nil, document: nil, counter:, image_options: {})
        @presenter = presenter
        @document = presenter&.document || document
        @counter = counter
        @image_options = { alt: '' }.merge(image_options)
      end

      def render?
        presenter.thumbnail.exists?
      end

      def use_thumbnail_tag_behavior?
        !presenter.thumbnail.instance_of?(Blacklight::ThumbnailPresenter)
      end

      def warn_about_deprecated_behavior
        Deprecation.warn(Blacklight::Document::ThumbnailComponent, 'Detected as custom thumbnail presenter; make sure it has a #render method that returns just the thumbnail image tag')
      end

      def presenter
        @presenter ||= @view_context.document_presenter(@document)
      end
    end
  end
end
