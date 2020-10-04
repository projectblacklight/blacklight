# frozen_string_literal: true

module Blacklight
  module System
    class DropdownComponent < ViewComponent::Base
      # rubocop:disable Metrics/ParameterLists
      def initialize(param:, choices:, search_state:, id: nil, classes: [], default: nil, selected: nil, interpolation: :field)
        @param = param
        @choices = choices
        @search_state = search_state
        @id = id
        @classes = classes.concat(['btn-group', "#{param.to_s.parameterize}-dropdown"])
        @selected = selected || default || option_text_and_value(@choices.first)&.first
        @interpolation = interpolation
      end
      # rubocop:enable Metrics/ParameterLists

      def render?
        @choices.many?
      end

      # rubocop:disable Style/CaseEquality
      # This method is from Rails to mirror how it handles native dropdowns
      def option_text_and_value(option)
        # Options are [text, value] pairs or strings used for both.
        if !option.is_a?(String) && option.respond_to?(:first) && option.respond_to?(:last)
          option = option.reject { |e| Hash === e } if Array === option
          [option.first, option.last]
        else
          [option, option]
        end
      end
      # rubocop:enable Style/CaseEquality

      def label_for_value(value)
        choice = @choices.find { |option| option_text_and_value(option).last == value }

        choice && option_text_and_value(choice).first
      end
    end
  end
end
