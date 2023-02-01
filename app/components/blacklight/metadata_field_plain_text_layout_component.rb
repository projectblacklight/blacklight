# frozen_string_literal: true

module Blacklight
  class MetadataFieldPlainTextLayoutComponent < Blacklight::MetadataFieldLayoutComponent
    with_collection_parameter :field

    def initialize(field:, **kwargs)
      super(field: field, **kwargs, value_tag: nil)
    end

    # rubocop:disable Rails/OutputSafety
    def call
      [label.to_s.strip, helpers.strip_tags(CGI.unescape_html(safe_join(values, "\n")).strip)].compact.join(' ').html_safe
    end
    # rubocop:enable Rails/OutputSafety
  end
end
