# frozen_string_literal: true

module Blacklight
  class ConstraintsComponent < ::ViewComponent::Base
    with_content_areas :query_constraints_area, :facet_constraints_area, :additional_constraints

    def initialize(search_state:,
                   id: 'appliedParams', classes: 'clearfix constraints-container',
                   query_constraint_component: Blacklight::ConstraintLayoutComponent, facet_constraint_component: Blacklight::ConstraintComponent)
      @search_state = search_state
      @query_constraint_component = query_constraint_component
      @facet_constraint_component = facet_constraint_component
      @id = id
      @classes = classes
    end

    def query_constraints
      return if @search_state.query_param.blank?

      label = @view_context.label_for_search_field(@search_state[:search_field]) unless @view_context.default_search_field?(@search_state[:search_field])

      @view_context.render(
        @query_constraint_component.new(
          search_state: @search_state,
          value: @search_state.query_param,
          label: label,
          remove_path: @view_context.remove_constraint_url(@search_state),
          classes: 'query'
        )
      )
    end

    def facet_constraints
      @view_context.render(@facet_constraint_component.with_collection(facet_item_presenters))
    end

    def start_over_path
      h = {}
      current_index_view_type = document_index_view_type(query_params)
      h[:view] = current_index_view_type unless current_index_view_type == default_document_index_view_type

      search_action_path(h)
    end

    def render?
      @search_state.has_constraints?
    end

    private

    def facet_item_presenters
      @search_state.filter_params.each_pair.flat_map do |facet, values|
        facet_config = @view_context.facet_configuration_for_field(facet)

        Array(values).map do |val|
          next if val.blank? # skip empty string

          facet_item_presenter(facet_config, val, facet)
        end
      end
    end

    def facet_item_presenter(facet_config, facet_item, facet_field)
      Blacklight::FacetItemPresenter.new(facet_item, facet_config, @view_context, facet_field)
    end
  end
end
