# frozen_string_literal: true

module Blacklight
  class FacetFieldListComponent < ::ViewComponent::Base
    def initialize(facet_field:, layout: nil)
      @facet_field = facet_field
      @layout = layout == false ? FacetFieldNoLayoutComponent : Blacklight::FacetFieldComponent
    end

    # Here for backwards compatibility only.
    # @private
    def render_facet_limit_list(*args)
      Deprecation.silence(Blacklight::FacetsHelperBehavior) do
        @view_context.render_facet_limit_list(*args)
      end
    end

    def render?
      @facet_field.paginator.items.any?
    end
  end
end
