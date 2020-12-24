# frozen_string_literal: true

module Blacklight
  class DocumentMetadataComponent < ::ViewComponent::Base
    with_collection_parameter :fields

    # @param fields [Enumerable<Blacklight::FieldPresenter>] Document field presenters
    def initialize(fields:, show: false, view_type: nil)
      @fields = fields
      @show = show
      @view_type = view_type
    end

    def render?
      @fields.any?
    end

    attr_reader :view_type

    def field_component(field)
      field.try(:component) || Blacklight::MetadataFieldComponent
    end
  end
end
