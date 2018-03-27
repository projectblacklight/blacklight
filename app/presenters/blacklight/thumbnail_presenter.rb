# frozen_string_literal: true

module Blacklight
  class ThumbnailPresenter
    attr_reader :document_presenter, :view_config

    # @param [IndexPresenter] document_presenter for linking and generating urls
    # @param [Blacklight::Configuration::ViewConfig] view_config
    def initialize(document_presenter, view_config)
      @document_presenter = document_presenter
      @view_config = view_config
    end

    ##
    # Does the document have a thumbnail to render?
    #
    # @return [Boolean]
    def exists?
      thumbnail_method.present? ||
        (thumbnail_field && thumbnail_value_from_document(document_presenter.document).present?) ||
        default_thumbnail.present?
    end

    ##
    # Render the thumbnail, if available, for a document and
    # link it to the document record.
    #
    # @param [Hash] image_options to pass to the image tag
    # @param [Hash] url_options to pass to IndexPresenter#link_to_document
    # @return [String]
    def thumbnail_tag image_options = {}, url_options = {}
      value = thumbnail_value(image_options)
      return value if value.nil? || url_options[:suppress_link]
      document_presenter.link_to_document value, url_options
    end

    private

    delegate :thumbnail_field, :thumbnail_method, :default_thumbnail, to: :view_config

    # @param [Hash] image_options to pass to the image tag
    def thumbnail_value(image_options)
      value = if thumbnail_method
                document_presenter.view_context.send(thumbnail_method, document_presenter.document, image_options)
              elsif thumbnail_field
                image_url = thumbnail_value_from_document(document_presenter.document)
                document_presenter.view_context.image_tag image_url, image_options if image_url.present?
              end

      value || default_thumbnail_value(image_options)
    end

    def default_thumbnail_value(image_options)
      return unless default_thumbnail

      case default_thumbnail
      when Symbol
        document_presenter.view_context.send(default_thumbnail, document_presenter.document, image_options)
      when Proc
        default_thumbnail.call(document_presenter.document, image_options)
      else
        document_presenter.view_context.image_tag default_thumbnail, image_options
      end
    end

    def thumbnail_value_from_document(document)
      Array(thumbnail_field).lazy.map { |field| document.first(field) }.reject(&:blank?).first
    end
  end
end
