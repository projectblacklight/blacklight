# frozen_string_literal: true

module Blacklight
  class ConstraintsComponent < ::ViewComponent::Base
    include Blacklight::ContentAreasShim

    renders_many :query_constraints_area
    renders_many :facet_constraints_area
    renders_many :additional_constraints

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
      if @search_state.query_param.present?
        @view_context.render(
          @query_constraint_component.new(
            search_state: @search_state,
            value: @search_state.query_param,
            label: label,
            remove_path: remove_path,
            classes: 'query'
          )
        )
      else
        ''.html_safe
      end + @view_context.render(@facet_constraint_component.with_collection(clause_presenters.to_a))
    end

    def remove_path
      helpers.search_action_path(@search_state.remove_query_params)
    end

    def facet_constraints
      @view_context.render(@facet_constraint_component.with_collection(facet_item_presenters.to_a))
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
          next if val.blank? # skip empty string

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
        field_config = @view_context.blacklight_config.search_fields[clause[:field]]
        yield Blacklight::ClausePresenter.new(key, clause, field_config, @view_context)
      end
    end

    def facet_item_presenter(facet_config, facet_item, facet_field)
      Blacklight::FacetItemPresenter.new(facet_item, facet_config, @view_context, facet_field)
    end

    def inclusive_facet_item_presenter(facet_config, facet_item, facet_field)
      Blacklight::InclusiveFacetItemPresenter.new(facet_item, facet_config, @view_context, facet_field)
    end
  end
end
