# frozen_string_literal: true

module Blacklight
  class DocumentMetadataComponent < Blacklight::Component
    renders_many :fields, (lambda do |component: nil, **kwargs|
      (component || Blacklight::MetadataFieldComponent).new(**kwargs)
    end)
    with_collection_parameter :fields

    # @param fields [Enumerable<Blacklight::FieldPresenter>] Document field presenters
    def initialize(fields: [], tag: 'dl', classes: %w[document-metadata dl-invert row], show: false, field_layout: nil, **component_args)
      @fields = fields
      @tag = tag
      @classes = classes
      @show = show
      @field_layout = field_layout
      @component_args = component_args
    end

    def before_render
      return unless fields

      @fields.each do |field|
        with_field(component: field_component(field), field: field, show: @show, layout: @field_layout)
      end
    end

    def render?
      fields.present?
    end

    def field_component(field)
      field&.component || Blacklight::MetadataFieldComponent
    end
  end
end
