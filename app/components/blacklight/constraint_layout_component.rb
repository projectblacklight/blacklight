# frozen_string_literal: true

module Blacklight
  class ConstraintLayoutComponent < ::ViewComponent::Base
    def initialize(value:, label: nil, remove_path: nil, classes: nil)
      @value = value
      @label = label
      @remove_path = remove_path
      @classes = Array(classes).join(' ')
    end

    def render?
      @value.present?
    end
  end
end
