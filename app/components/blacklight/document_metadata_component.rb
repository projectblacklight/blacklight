# frozen_string_literal: true

module Blacklight
  class DocumentMetadataComponent < ::ViewComponent::Base
    renders_many :fields, (lambda do |component: nil, **kwargs|
      (component || Blacklight::MetadataFieldComponent).new(**kwargs)
    end)
    with_collection_parameter :fields

    # @param fields [Enumerable<Blacklight::FieldPresenter>] Document field presenters
    def initialize(fields: [], show: false, view_type: nil)
      @fields = fields
      @show = show
      @view_type = view_type
    end

    def before_render
      return unless fields

      @fields.each do |field|
        field(component: field_component(field), field: field, show: @show, view_type: @view_type)
      end
    end

    def render?
      fields.present?
    end

    attr_reader :view_type

    def field_component(field)
      field&.component || Blacklight::MetadataFieldComponent
    end
  end
end
