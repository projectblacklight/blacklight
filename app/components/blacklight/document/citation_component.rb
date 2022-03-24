# frozen_string_literal: true

module Blacklight
  module Document
    # Render citations for the document
    class CitationComponent < Blacklight::Component
      DEFAULT_FORMATS = {
        'blacklight.citation.mla': :export_as_mla_citation_txt,
        'blacklight.citation.apa': :export_as_apa_citation_txt,
        'blacklight.citation.chicago': :export_as_chicago_citation_txt
      }.freeze

      with_collection_parameter :document

      # @param [Blacklight::Document] document
      # @param [Hash<String => Symbol>] formats map of citation format names (suspiciously, i18n keys
      #   for them) to document methods that return the formatted citation.
      def initialize(document:, formats: DEFAULT_FORMATS)
        @document = document
        @formats = formats.select { |_k, v| @document.respond_to?(v) }
      end

      # @return [String]
      def title
        presenter.heading
      end

      def presenter
        helpers.document_presenter(@document)
      end
    end
  end
end
