# frozen_string_literal: true

module Blacklight
  module Icons
    # Circle-half icon (Bootstrap Icons bi-circle-half) representing the auto/system theme.
    # You can override the default svg by setting:
    #   Blacklight::Icons::CircleHalfComponent.svg = '<svg>your SVG here</svg>'
    class CircleHalfComponent < Blacklight::Icons::IconComponent
      self.svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-circle-half" viewBox="0 0 16 16">
          <path d="M8 15A7 7 0 1 0 8 1zm0 1A8 8 0 1 1 8 0a8 8 0 0 1 0 16"/>
        </svg>
      SVG
    end
  end
end
