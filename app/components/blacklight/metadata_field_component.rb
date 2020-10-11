# frozen_string_literal: true

module Blacklight
  class MetadataFieldComponent < ::ViewComponent::Base
    with_collection_parameter :field

    # @param field [Blacklight::FieldPresenter]
    # @param layout [Blacklight::MetadataFieldLayoutComponent] alternate layout component to use
    # @param show [Boolean] are we showing only a single document (vs a list of search results); used for backwards-compatibility
    def initialize(field:, layout: nil, show: false)
      @field = field
      @layout = layout || Blacklight::MetadataFieldLayoutComponent
      @show = show
    end

    # @private
    def label
      if @show
        @field.label('show')
      else
        @field.label
      end
    end

    def render?
      @field.render_field?
    end
  end
end
