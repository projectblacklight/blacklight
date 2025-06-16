# frozen_string_literal: true

module Blacklight
  module Document
    # Render the thumbnail for the document
    class ThumbnailComponent < Blacklight::Component
      with_collection_parameter :presenter

      # @param [Blacklight::DocumentPresenter] presenter
      # @param [Integer] counter
      # @param [Hash] image_options options for the thumbnail presenter's image tag
      def initialize(counter:, presenter: nil, image_options: {})
        @presenter = presenter
        @counter = counter
        @image_options = { alt: '' }.merge(image_options)
      end

      attr_accessor :presenter

      def thumbnail_value
        @thumbnail_value ||= presenter.thumbnail.render(@image_options)
      end

      def render?
        presenter.thumbnail && thumbnail_value
      end
    end
  end
end
