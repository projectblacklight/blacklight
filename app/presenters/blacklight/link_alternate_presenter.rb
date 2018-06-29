# frozen_string_literal: true

module Blacklight
  # Create <link rel="alternate"> links from a documents dynamically
  class LinkAlternatePresenter
    include ActionView::Helpers::OutputSafetyHelper
    include ActionView::Helpers::TagHelper

    def initialize(view_context, document, options)
      @view_context = view_context
      @document = document
      @options = { unique: false, exclude: [] }.merge(options)
    end

    attr_reader :view_context, :document, :options

    # Renders links to alternate representations
    # provided by export formats. Returns empty string if no links available.
    def render
      seen = Set.new

      safe_join(document.export_formats.map do |format, spec|
        next if options[:exclude].include?(format) || (options[:unique] && seen.include?(spec[:content_type]))

        seen.add(spec[:content_type])

        tag(:link, rel: "alternate", title: format, type: spec[:content_type], href: href(format))
      end.compact, "\n")
    end

    def href(format)
      view_context.polymorphic_url(view_context.search_state.url_for_document(document), format: format)
    end
  end
end
