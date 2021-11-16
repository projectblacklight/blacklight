# frozen_string_literal: true

module Blacklight
  class MetadataFieldLayoutComponent < ::ViewComponent::Base
    with_collection_parameter :field
    renders_one :label
    renders_many :values, (lambda do |value: nil, &block|
      if block
        content_tag :dd, class: "#{@value_class} blacklight-#{@key}", &block
      else
        content_tag :dd, value, class: "#{@value_class} blacklight-#{@key}"
      end
    end)

    # @param field [Blacklight::FieldPresenter]
    def initialize(field:, label_class: 'col-md-3', value_class: 'col-md-9')
      @field = field
      @key = @field.key.parameterize
      @label_class = label_class
      @value_class = value_class
    end
  end
end
