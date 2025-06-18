# frozen_string_literal: true

module Blacklight
  class ConstraintLayoutComponent < Blacklight::Component
    def initialize(value:, label: nil, remove_path: nil, classes: nil, search_state: nil)
      @value = value
      @label = label
      @remove_path = remove_path
      @classes = Array(classes).join(' ')
      @search_state = search_state
    end

    def remove_aria_label
      if @label.blank?
        t('blacklight.search.filters.remove.value', value: @value)
      else
        t('blacklight.search.filters.remove.label_value', label: @label, value: @value)
      end
    end

    def render?
      @value.present?
    end

    def remove_button
      return unless @remove_path

      link_to(@remove_path, class: 'btn btn-outline-secondary remove d-flex align-items-center justify-content-center') do
        render(Blacklight::Icons::RemoveComponent.new(aria_hidden: true)) +
          tag.span(remove_aria_label, class: "visually-hidden")
      end
    end
  end
end
