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
end
