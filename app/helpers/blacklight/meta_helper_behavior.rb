# frozen_string_literal: true

module Blacklight
  # Methods used to add <meta> tags to the <head>
  module MetaHelperBehavior
    # Hash of property:content pairs that will become <meta> tags
    def open_graph_properties
      @open_graph_properties ||= {}
    end

    # Add additional properties to the hash that will be rendered.
    # Passing nil here means "remove this property".
    def add_open_graph_properties(properties)
      open_graph_properties.merge! properties.transform_keys(&:to_s)
    end

    # Add properties if they are not already set; ignore nil values.
    # Use this from the layout, which renders after the view has set its own properties.
    def add_default_open_graph_properties(properties)
      open_graph_properties.reverse_merge! properties.transform_keys(&:to_s).compact
    end

    # Base set of properties that will be rendered on every page
    def default_open_graph_properties
      {
        'og:type' => 'website',
        'og:site_name' => application_name,
        'og:title' => render_page_title,
        'og:url' => request.original_url
      }
    end

    # Render all entries in open_graph_properties as <meta> tags
    def render_open_graph_tags
      add_default_open_graph_properties(default_open_graph_properties)
      safe_join(open_graph_properties.compact_blank.map { |property, content| tag.meta(property:, content:) }, "\n")
    end
  end
end
