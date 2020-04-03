# frozen_string_literal: true

module Blacklight
  class DocumentMetadataComponent < ::ViewComponent::Base
    with_collection_parameter :fields

    # @param fields [Enumerable<Blacklight::FieldPresenter>] Document field presenters
    def initialize(fields:, show: false)
      @fields = fields
      @show = show
    end

    def render?
      @fields.any?
    end

    def field_component(field)
      field.try(:component) || Blacklight::MetadataFieldComponent
    end
  end
end
