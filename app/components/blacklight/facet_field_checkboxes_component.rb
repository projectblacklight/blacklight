# frozen_string_literal: true

module Blacklight
  class FacetFieldCheckboxesComponent < ::ViewComponent::Base
    def initialize(facet_field:, layout: nil)
      @facet_field = facet_field
      @layout = layout == false ? FacetFieldNoLayoutComponent : Blacklight::FacetFieldComponent
    end

    def render?
      presenters.any?
    end

    def presenters
      return [] unless @facet_field.paginator

      return to_enum(:presenters) unless block_given?

      @facet_field.paginator.items.each do |item|
        yield Blacklight::FacetItemPresenter.new(item, @facet_field.facet_field, @view_context, @facet_field.key, @facet_field.search_state)
      end
    end
  end
end
