# frozen_string_literal: true
module Blacklight::FacetsHelperBehavior
  extend Deprecation
  self.deprecation_horizon = 'blacklight 8.0'

  delegate :facet_configuration_for_field, to: :blacklight_config

  def facet_field_presenter(facet_config, display_facet)
    (facet_config.presenter || Blacklight::FacetFieldPresenter).new(facet_config, display_facet, self)
  end

  ##
  # Get the displayable version of a facet's value
  #
  # @param [Object] field
  # @param [String] item value
  # @return [String]
  # @deprecated
  def facet_display_value field, item
    deprecated_method(:facet_display_value)
    facet_config = facet_configuration_for_field(field)
    facet_item_presenter(facet_config, item, field).label
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

  # We can't use .deprecation_deprecate here, because the new components need to
  # see the originally defined location for these methods in order to properly
  # call back into the helpers for backwards compatibility
  def deprecated_method(method_name)
    Deprecation.warn(Blacklight::FacetsHelperBehavior,
                     Deprecation.deprecated_method_warning(Blacklight::FacetsHelperBehavior,
                                                           method_name, {}),
                     caller)
  end
end
