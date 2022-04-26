# frozen_string_literal: true

module Blacklight
  class DocumentMetadataComponent < Blacklight::Component
    renders_many :fields, (lambda do |component: nil, **kwargs|
      (component || Blacklight::MetadataFieldComponent).new(**kwargs)
    end)
    with_collection_parameter :fields

    # @param fields [Enumerable<Blacklight::FieldPresenter>] Document field presenters
    def initialize(fields: [], show: false)
      @fields = fields
      @show = show
    end

    def before_render
      return unless fields

      @fields.each do |field|
        field(component: field_component(field), field: field, show: @show)
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
