# frozen_string_literal: true

module Blacklight
  class FacetFieldNoLayoutComponent < ::ViewComponent::Base
    include Blacklight::ContentAreasShim

    renders_one :label
    renders_one :body

    def initialize(**); end

    def call
      body.to_s
    end
  end
end
