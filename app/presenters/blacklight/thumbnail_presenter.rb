# frozen_string_literal: true

module Blacklight
  class ThumbnailPresenter
    attr_reader :document, :view_context, :view_config

    # @param [SolrDocument] document
    # @param [ActionView::Base] view_context scope for linking and generating urls
    # @param [Blacklight::Configuration::ViewConfig] view_config
    def initialize(document, view_context, view_config)
      @document = document
      @view_context = view_context
      @view_config = view_config
    end

    ##
    # Does the document have a thumbnail to render?
    #
    # @return [Boolean]
    def exists?
      thumbnail_method.present? || thumbnail_field && document.has?(thumbnail_field)
    end

    ##
    # Render the thumbnail, if available, for a document and
    # link it to the document record.
    #
    # @param [Hash] image_options to pass to the image tag
    # @param [Hash] url_options to pass to #link_to_document
    # @return [String]
    # rubocop:disable Lint/AssignmentInCondition
    def thumbnail_tag image_options = {}, url_options = {}
      return unless value = thumbnail_value(image_options)
      return value if url_options[:suppress_link]
      view_context.link_to_document document, value, url_options
    end
    # rubocop:enable Lint/AssignmentInCondition

    private

    delegate :thumbnail_field, :thumbnail_method, to: :view_config

    # @param [Hash] image_options to pass to the image tag
    def thumbnail_value(image_options)
      if thumbnail_method
        view_context.send(thumbnail_method, document, image_options)
      elsif thumbnail_field
        url = document.first(thumbnail_field)
        view_context.image_tag url, image_options if url.present?
      end
    end
  end
end
