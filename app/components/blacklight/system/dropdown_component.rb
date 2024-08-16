# frozen_string_literal: true

module Blacklight
  module System
    class DropdownComponent < Blacklight::Component
      renders_one :button, DropdownButtonComponent

      renders_many :options, (lambda do |text:, url:, selected: false|
        link_to(text, url, class: "dropdown-item #{'active' if selected}", role: 'menuitem', aria: { current: ('page' if selected) })
      end)

      # rubocop:disable Metrics/ParameterLists
      def initialize(param:, choices:, search_state:, id: nil, classes: [], default: nil, selected: nil, interpolation: :field)
        @param = param
        @choices = choices
        @search_state = search_state
        @id = id
        @classes = classes.push('btn-group', "#{param.to_s.parameterize}-dropdown")
        @selected = selected || default || option_text_and_value(@choices.first)&.first
        @interpolation = interpolation
      end
      # rubocop:enable Metrics/ParameterLists

      def button_label
        t(:button_label_html, default: :label_html, scope: "blacklight.search.#{@param}", @interpolation => label_for_value(@selected))
      end

      def before_render
        with_button(label: button_label) unless button

        return if options.any?

        with_options(@choices.map do |option|
          text, value = option_text_and_value(option)
          { text: text, url: helpers.url_for(@search_state.params_for_search(@param => value)), selected: @selected == value }
        end)
      end

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
