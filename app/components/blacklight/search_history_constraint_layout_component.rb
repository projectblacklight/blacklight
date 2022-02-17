# frozen_string_literal: true

module Blacklight
  # Override the regular constraint layout to remove any interactive features so this can
  # be treated as quasi-plain text
  class SearchHistoryConstraintLayoutComponent < Blacklight::ConstraintLayoutComponent
    def call
      label = tag.span(t('blacklight.search.filters.label', label: @label), class: 'filter-name') if @label.present?
      value = tag.span(@value, class: 'filter-values')

      tag.span(safe_join([label, value].compact), class: 'constraint')
    end
  end
end
