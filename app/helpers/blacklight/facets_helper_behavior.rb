# frozen_string_literal: true

module Blacklight::FacetsHelperBehavior
  delegate :facet_configuration_for_field, to: :blacklight_config

  def facet_field_presenter(facet_config, display_facet)
    facet_config.presenter.new(facet_config, display_facet, self)
  end

  def search_facet_path(options = {})
    opts = search_state
           .to_h
           .merge(action: "facet", only_path: true)
           .merge(options)
           .except(:page)
    url_for opts
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
    facet_config.item_presenter.new(facet_item, facet_config, self, facet_field)
  end
end
