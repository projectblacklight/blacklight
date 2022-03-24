# frozen_string_literal: true

module Blacklight
  module Document
    # Render the thumbnail for the document
    class ThumbnailComponent < Blacklight::Component
      with_collection_parameter :presenter

      # @param [Blacklight::DocumentPresenter] presenter
      # @param [Integer] counter
      # @param [Hash] image_options options for the thumbnail presenter's image tag
      def initialize(counter:, presenter: nil, document: nil, image_options: {})
        @presenter = presenter
        @document = presenter&.document || document
        @counter = counter
        @image_options = { alt: '' }.merge(image_options)
      end

      def render?
        presenter.thumbnail.exists?
      end

      def presenter
        @presenter ||= helpers.document_presenter(@document)
      end
    end
  end
end
