# frozen_string_literal: true

module Blacklight
  # Renders <meta> tags in the <head> with Open Graph metadata
  class OpenGraphMetadataComponent < Blacklight::Component
    attr_reader :presenter

    # @param presenter [#properties, nil] page-specific Open Graph properties
    def initialize(presenter: nil)
      @presenter = presenter
    end

    # Hash of property:content pairs that will become <meta> tags
    def properties
      default_properties.merge((presenter&.properties || {}).transform_keys(&:to_s)).compact_blank
    end

    # Base set of properties that will be rendered on every page
    def default_properties
      {
        'og:type' => 'website',
        'og:site_name' => helpers.application_name,
        'og:title' => helpers.render_page_title,
        'og:url' => request.original_url
      }
    end

    # Render all entries in properties as <meta> tags
    def call
      safe_join(properties.map { |property, content| tag.meta(property:, content: helpers.strip_tags(content)) }, "\n")
    end
  end
end
