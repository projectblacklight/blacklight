# frozen_string_literal: true
module Blacklight
  class Configuration::DisplayField < Blacklight::Configuration::Field
    ##
    # The following is a non-exhaustive list of display field config parameters that are used
    # by Blacklight directly. Application-specific code or plugins may add or replace
    # the parameters and behaviors specified below.
    #

    ##
    # Data parameters:
    # @!attribute values
    #  @return [Proc]
    # @!attribute accessor
    #  @return [Boolean,Symbol]
    # @!attribute highlight
    #  @return [Boolean]
    # @!attribute default
    #  @return [Object]
    # @!attribute solr_params
    #  @return [Hash]
    # @!attribute include_in_request
    #  @return [Boolean]

    ##
    # Rendering:
    # @!attribute presenter
    #   @return [Blacklight::FieldPresenter]
    # @!attribute component
    #   @return [Blacklight::MetadataFieldComponent]

    ##
    # Default rendering pipeline:
    # @!attribute link_to_facet
    #   @return [Boolean]
    # @!attribute link_to_search
    #   @deprecated use link_to_facet instead.
    #   @return [Boolean]
    # @!attribute itemprop
    #   @return [String]
    # @!attribute separator_options
    #   @return [Hash]

    # @param [Blacklight::Configuration] _blacklight_config
    def normalize! _blacklight_config = nil
      super
      self.presenter ||= Blacklight::FieldPresenter
    end
  end
end
