# frozen_string_literal: true

module Blacklight
  class MetadataFieldLayoutComponent < ::ViewComponent::Base
    include Blacklight::ContentAreasShim

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

    def value(*args, **kwargs, &block)
      return set_slot(:values, *args, **kwargs, &block) if block_given?

      Deprecation.warn(Blacklight::MetadataFieldLayoutComponent, 'The `value` content area is deprecated; render from the values slot instead')

      values.first
    end

    def with(slot_name, *args, **kwargs, &block)
      if slot_name == :value
        super(:values, *args, **kwargs, &block)
      else
        super
      end
    end
  end
end
