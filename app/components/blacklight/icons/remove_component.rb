# frozen_string_literal: true

module Blacklight
  module Icons
    # This is the remove (x) icon for the facets and constraints.
    # You can override the default svg by setting:
    #   Blacklight::Icons::RemoveComponent.svg = '<svg>your SVG here</svg>'
    class RemoveComponent < Blacklight::Icons::IconComponent
      self.svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x-lg" viewBox="0 0 16 16">
          <path d="M2.146 2.854a.5.5 0 1 1 .708-.708L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8z"/>
        </svg>
      SVG
    end
  end
end
