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

      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
        @view_context.render(
          @query_constraint_component.new(
            search_state: @search_state,
            value: @search_state.query_param,
            label: @view_context.constraint_query_label(@search_state.params),
            remove_path: @view_context.remove_constraint_url(@search_state),
            classes: 'query'
          )
        )
      end
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
      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) { @view_context.query_has_constraints? }
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
