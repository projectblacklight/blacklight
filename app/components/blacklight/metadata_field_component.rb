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
      Deprecation.silence(Blacklight::BlacklightHelperBehavior) do
        if @show
          @view_context.render_document_show_field_label @field.document, label: @field.label('show'), field: @field.key
        else
          @view_context.render_index_field_label @field.document, label: @field.label, field: @field.key
        end
      end
    end

    def render?
      @field.render_field?
    end
  end
end
