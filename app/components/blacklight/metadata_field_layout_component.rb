# frozen_string_literal: true

module Blacklight
  class MetadataFieldLayoutComponent < Blacklight::Component
    with_collection_parameter :field
    renders_one :label
    renders_many :values, (lambda do |index:, value: nil, &block|
      classes = [@value_class, "blacklight-#{@key}"]
      classes.unshift @offset_class unless index.zero?
      classes.join(' ')

      if @value_tag.nil?
        block&.call || value
      elsif block
        content_tag @value_tag, class: classes, &block
      else
        content_tag @value_tag, value, class: classes
      end
    end)

    # @param field [Blacklight::FieldPresenter]
    def initialize(field:, value_tag: 'dd', label_class: 'col-md-3', value_class: 'col-md-9', offset_class: 'offset-md-3')
      @field = field
      @key = @field.key.parameterize
      @label_class = label_class
      @value_tag = value_tag
      @value_class = value_class
      @offset_class = offset_class
    end
  end
end
