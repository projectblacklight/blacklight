# frozen_string_literal: true

module Blacklight
  module Document
    class CitationComponent < ::ViewComponent::Base
      DEFAULT_FORMATS = {
        'blacklight.citation.mla': :export_as_mla_citation_txt,
        'blacklight.citation.apa': :export_as_apa_citation_txt,
        'blacklight.citation.chicago': :export_as_chicago_citation_txt
      }.freeze

      with_collection_parameter :document

      def initialize(document:, formats: DEFAULT_FORMATS)
        @document = document
        @formats = formats.select { |_k, v| @document.respond_to?(v) }
      end

      def title
        @view_context.document_heading(@document)
      end
    end
  end
end
