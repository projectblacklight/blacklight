# frozen_string_literal: true

module Blacklight
  class ConstraintsComponent < ::ViewComponent::Base
    include Blacklight::ContentAreasShim

    renders_many :query_constraints_area
    renders_many :facet_constraints_area
    renders_many :additional_constraints

    # rubocop:disable Metrics/ParameterLists
    def initialize(search_state:,
                   tag: :div,
                   render_headers: true,
                   id: 'appliedParams', classes: 'clearfix constraints-container',
                   query_constraint_component: Blacklight::ConstraintLayoutComponent,
                   query_constraint_component_options: {},
                   facet_constraint_component: Blacklight::ConstraintComponent,
                   facet_constraint_component_options: {},
                   start_over_component: Blacklight::StartOverButtonComponent)
      @search_state = search_state
      @query_constraint_component = query_constraint_component
      @query_constraint_component_options = query_constraint_component_options
      @facet_constraint_component = facet_constraint_component
      @facet_constraint_component_options = facet_constraint_component_options
      @start_over_component = start_over_component
      @render_headers = render_headers
      @tag = tag
      @id = id
      @classes = classes
    end
    # rubocop:enable Metrics/ParameterLists

    def query_constraints
      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
        if @search_state.query_param.present?
          @view_context.render(
            @query_constraint_component.new(
              search_state: @search_state,
              value: @search_state.query_param,
              label: label,
              remove_path: @view_context.remove_constraint_url(@search_state),
              classes: 'query',
              **@query_constraint_component_options
            )
          )
        else
          ''.html_safe
        end
      end + @view_context.render(@facet_constraint_component.with_collection(clause_presenters.to_a, **@facet_constraint_component_options))
    end

    def facet_constraints
      @view_context.render(@facet_constraint_component.with_collection(facet_item_presenters.to_a, **@facet_constraint_component_options))
    end

    def render?
      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) { @view_context.query_has_constraints? }
    end

    private

    # @deprecated
    def start_over_path
      Deprecation.silence(Blacklight::UrlHelperBehavior) do
        helpers.start_over_path
      end
    end

    def label
      Deprecation.silence(Blacklight::ConfigurationHelperBehavior) do
        @view_context.constraint_query_label(@search_state.params)
      end
    end

    def facet_item_presenters
      return to_enum(:facet_item_presenters) unless block_given?

      Deprecation.silence(Blacklight::SearchState) do
        @search_state.filters.map do |facet|
          facet.values.map do |val|
            next if val.blank?

            if val.is_a?(Array)
              yield inclusive_facet_item_presenter(facet.config, val, facet.key) if val.any?(&:present?)
            else
              yield facet_item_presenter(facet.config, val, facet.key)
            end
          end
        end
      end
    end

    def clause_presenters
      return to_enum(:clause_presenters) unless block_given?

      @search_state.clause_params.each do |key, clause|
        field_config = @view_context.blacklight_config.search_fields[clause[:field]]
        yield Blacklight::ClausePresenter.new(key, clause, field_config, @view_context)
      end
    end

    def facet_item_presenter(facet_config, facet_item, facet_field)
      (facet_config.item_presenter || Blacklight::FacetItemPresenter).new(facet_item, facet_config, @view_context, facet_field)
    end

    def inclusive_facet_item_presenter(facet_config, facet_item, facet_field)
      Blacklight::InclusiveFacetItemPresenter.new(facet_item, facet_config, @view_context, facet_field)
    end
  end
end
