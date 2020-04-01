# frozen_string_literal: true

module Blacklight
  class FacetFieldNoLayoutComponent < ::ViewComponent::Base
    with_content_areas :label, :body

    def initialize(**); end

    def call
      body
    end
  end
end
