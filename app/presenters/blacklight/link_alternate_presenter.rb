module Blacklight
  # Create <link rel="alternate"> links from a documents dynamically
  class LinkAlternatePresenter
    include ActionView::Helpers::OutputSafetyHelper
    include ActionView::Helpers::TagHelper

    def initialize(controller, document, options)
      @controller = controller
      @document = document
      @options = { unique: false, exclude: [] }.merge(options)
    end

    attr_reader :controller, :document, :options

    # Renders links to alternate representations 
    # provided by export formats. Returns empty string if no links available.
    def render
      seen = Set.new

      safe_join(document.export_formats.map do |format, spec|
        next if options[:exclude].include?(format) || (options[:unique] && seen.include?(spec[:content_type]))

        seen.add(spec[:content_type])

        tag(:link, rel: "alternate", title: format, type: spec[:content_type], href: controller.polymorphic_url(document, format: format))
      end.compact, "\n")
    end
  end
end
