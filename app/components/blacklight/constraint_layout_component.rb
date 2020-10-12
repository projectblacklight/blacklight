# frozen_string_literal: true

module Blacklight
  class ConstraintLayoutComponent < ::ViewComponent::Base
    def initialize(value:, label: nil, remove_path: nil, classes: nil, search_state: nil)
      @value = value
      @label = label
      @remove_path = remove_path
      @classes = Array(classes).join(' ')
      @search_state = search_state
    end

    def render?
      @value.present?
    end
  end
end
