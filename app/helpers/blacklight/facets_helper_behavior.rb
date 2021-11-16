# frozen_string_literal: true
module Blacklight::FacetsHelperBehavior
  delegate :facet_configuration_for_field, to: :blacklight_config

  def facet_field_presenter(facet_config, display_facet)
    (facet_config.presenter || Blacklight::FacetFieldPresenter).new(facet_config, display_facet, self)
  end

  private

  def facet_value_for_facet_item item
    if item.respond_to? :value
      item.value
    else
      item
    end
  end

  def facet_item_presenter(facet_config, facet_item, facet_field)
    Blacklight::FacetItemPresenter.new(facet_item, facet_config, self, facet_field)
  end
end
