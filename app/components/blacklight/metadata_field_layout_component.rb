# frozen_string_literal: true

module Blacklight
  class MetadataFieldLayoutComponent < ::ViewComponent::Base
    with_collection_parameter :field
    with_content_areas :label, :value

    # @param field [Blacklight::FieldPresenter]
    def initialize(field:, label_class: 'col-md-3', value_class: 'col-md-9')
      @field = field
      @key = @field.key.parameterize
      @label_class = label_class
      @value_class = value_class
    end
  end
end
