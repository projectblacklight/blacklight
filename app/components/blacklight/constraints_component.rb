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

      @view_context.render(
        @query_constraint_component.new(
          search_state: @search_state,
          value: @search_state.query_param,
          label: constraint_query_label,
          remove_path: remove_path,
          classes: 'query'
        )
      )
    end

    ##
    # @return [String] a label for the currently selected search field.
    # If no "search_field" or the default (e.g. "all_fields") is selected, then return nil
    # Otherwise grab the label of the selected search field.
    def constraint_query_label
      search_field = @search_state.params[:search_field]
      helpers.label_for_search_field(search_field) unless helpers.default_search_field?(search_field)
    end

    def remove_path
      helpers.search_action_path(@search_state.remove_query_params)
    end

    def facet_constraints
      @view_context.render(@facet_constraint_component.with_collection(facet_item_presenters))
    end

    def start_over_path
      Deprecation.silence(Blacklight::UrlHelperBehavior) do
        @view_context.start_over_path
      end
    end

    def render?
      @search_state.has_constraints?
    end

    private

    def facet_item_presenters
      Deprecation.silence(Blacklight::SearchState) do
        @search_state.filter_params.each_pair.flat_map do |facet, values|
          facet_config = @view_context.facet_configuration_for_field(facet)

          Array(values).map do |val|
            next if val.blank? # skip empty string

            facet_item_presenter(facet_config, val, facet)
          end
        end
      end
    end

    def facet_item_presenter(facet_config, facet_item, facet_field)
      Blacklight::FacetItemPresenter.new(facet_item, facet_config, @view_context, facet_field)
    end
  end
end
