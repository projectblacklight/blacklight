# frozen_string_literal: true

module Blacklight
  module Icons
    # This is the remove (x) icon for the facets and constraints.
    # You can override the default svg by setting:
    #   Blacklight::Icons::RemoveComponent.svg = '<svg>your SVG here</svg>'
    class RemoveComponent < Blacklight::Icons::IconComponent
      self.svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x fs-4" viewBox="0 0 16 16">
          <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708"/>
        </svg>
      SVG
    end
  end
end
