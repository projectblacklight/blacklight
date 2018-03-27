# frozen_string_literal: true
module Blacklight::FacetsHelperBehavior
  include Blacklight::Facet

  ##
  # Determine whether a facet should be rendered as collapsed or not.
  #   - if the facet is 'active', don't collapse
  #   - if the facet is configured to collapse (the default), collapse
  #   - if the facet is configured not to collapse, don't collapse
  #
  # @param [Blacklight::Configuration::FacetField] facet_field
  # @return [Boolean]
  def should_collapse_facet? facet_field
    !facet_field_in_params?(facet_field.key) && facet_field.collapse
  end

  ##
  # Are any facet restrictions for a field in the query parameters?
  #
  # @param [String] field
  # @return [Boolean]
  def facet_field_in_params? field
    !facet_params(field).blank?
  end

  ##
  # Check if the query parameters have the given facet field with the
  # given value.
  #
  # @param [Object] field
  # @param [Blacklight::Solr::Response::Facets::FacetItem, String] item facet value
  # @return [Boolean]
  def facet_in_params?(field, item)
    value = item.respond_to?(:value) ? item.value : item

    (facet_params(field) || []).include? value
  end

  ##
  # Get the values of the facet set in the blacklight query string
  def facet_params field
    config = facet_configuration_for_field(field)

    params[:f][config.key] if params[:f]
  end

  def facet_field_id facet_field
    "facet-#{facet_field.key.parameterize}"
  end
end
