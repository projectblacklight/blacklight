# frozen_string_literal: true

module Blacklight
  class FacetFieldListRangeFormComponent < Blacklight::Component
    delegate :search_action_path, to: :helpers

    def initialize(facet_field:)
      @facet_field = facet_field
    end

    def start_label
      t('blacklight.search.facets.range.form.start_label', field_label: @facet_field.label)
    end

    def end_label
      t('blacklight.search.facets.range.form.end_label', field_label: @facet_field.label)
    end

    def input_options
      return {} unless range_config

      range_config.fetch(:input, {})
                  .slice(:min, :max, :placeholder, :step)
    end

    # type is 'start' or 'end'
    def render_range_input(type, input_label = nil)
      type = type.to_s

      default = if @facet_field.selected_range.is_a?(Range)
                  case type
                  when 'start' then @facet_field.selected_range.first
                  when 'end' then @facet_field.selected_range.last
                  end
                end
      html = number_field_tag("range[#{@facet_field.key}][#{type}]", default, class: "form-control text-center range_#{type}", **input_options)
      html += label_tag("range[#{@facet_field.key}][#{type}]", input_label, class: 'sr-only visually-hidden') if input_label.present?
      html
    end

    private

    ##
    # the form needs to serialize any search parameters, including other potential range filters,
    # as hidden fields. The parameters for this component's range filter are serialized as number
    # inputs, and should not be in the hidden params.
    # @return [Blacklight::HiddenSearchStateComponent]
    def hidden_search_state
      hidden_search_params = @facet_field.search_state.params_for_search.except(:utf8, :page)
      hidden_search_params[:range]&.except!(@facet_field.key)
      Blacklight::HiddenSearchStateComponent.new(params: hidden_search_params)
    end

    def range_config
      config = @facet_field.facet_field.range
      config == true ? {} : config
    end
  end
end
