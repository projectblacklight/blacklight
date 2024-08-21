# frozen_string_literal: true

module Blacklight
  class ConstraintsComponent < Blacklight::Component
    renders_many :query_constraints_area
    renders_many :facet_constraints_area
    renders_many :additional_constraints

    def self.for_search_history(**kwargs)
      new(tag: :span,
          render_headers: false,
          id: nil,
          query_constraint_component: Blacklight::SearchHistoryConstraintLayoutComponent,
          facet_constraint_component_options: { layout: Blacklight::SearchHistoryConstraintLayoutComponent },
          start_over_component: nil,
          **kwargs)
    end

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
      if @search_state.query_param.present?
        render(
          @query_constraint_component.new(
            search_state: @search_state,
            value: @search_state.query_param,
            label: label,
            remove_path: remove_path,
            classes: 'query',
            **@query_constraint_component_options
          )
        )
      else
        ''.html_safe
      end + render(@facet_constraint_component.with_collection(clause_presenters.to_a, **@facet_constraint_component_options))
    end

    def remove_path
      helpers.search_action_path(@search_state.remove_query_params)
    end

    def facet_constraints
      render(@facet_constraint_component.with_collection(facet_item_presenters.to_a, **@facet_constraint_component_options))
    end

    def render?
      @search_state.has_constraints?
    end

    private

    def label
      search_field = @search_state.params[:search_field]
      helpers.label_for_search_field(search_field) unless helpers.default_search_field?(search_field)
    end

    def facet_item_presenters
      return to_enum(:facet_item_presenters) unless block_given?

      @search_state.filters.map do |facet|
        facet.each_value do |val|
          next if val.blank?

          if val.is_a?(Array)
            yield inclusive_facet_item_presenter(facet.config, val, facet.key) if val.any?(&:present?)
          else
            yield facet_item_presenter(facet.config, val, facet.key)
          end
        end
      end
    end

    def clause_presenters
      return to_enum(:clause_presenters) unless block_given?

      @search_state.clause_params.each do |key, clause|
        field_config = helpers.blacklight_config.search_fields[clause[:field]]
        yield Blacklight::ClausePresenter.new(key, clause, field_config, helpers)
      end
    end

    def facet_item_presenter(facet_config, facet_item, facet_field)
      facet_config.item_presenter.new(facet_item, facet_config, helpers, facet_field)
    end

    def inclusive_facet_item_presenter(facet_config, facet_item, facet_field)
      Blacklight::InclusiveFacetItemPresenter.new(facet_item, facet_config, helpers, facet_field)
    end
  end
end
