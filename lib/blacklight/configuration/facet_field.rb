# frozen_string_literal: true
module Blacklight
  class Configuration::FacetField < Blacklight::Configuration::Field
    ##
    # The following is a non-exhaustive list of facet config parameters that are used
    # by Blacklight directly. Application-specific code or plugins may add or replace
    # the parameters and behaviors specified below.
    #

    ##
    # Display parameters:
    # @!attribute collapse
    #   @return [Boolean] whether to display the facet in a collapsed state by default
    # @!attribute show
    #   @return [Boolean] whether to show the facet to the user or not (very similar to the more generic if/unless)
    # @!attribute index_range
    #   @return [Enumerable] a list of facet prefixes (default: A-Z) to allow users to 'jump' to particular values
    # @!attribute date
    #   @return [Symbol|Hash] the i18n localization option for a date or time value; used as the second parameter for the I18n.l method
    # @!attribute link_to_facet
    #   @return [Boolean]
    # @!attribute link_to_search
    #   @deprecated use link_to_facet instead.
    #   @return [Boolean]
    # @!attribute helper_method
    #   @return [Symbol] the name of a helper method used to display the facet's value to the user; it receives the facet value.
    # @!attribute url_method
    #   @return [Symbol] The name of a helper to use for getting the url for a facet link; the method will receive the facet field's key and value.
    # @!attribute collapsing
    #   @return [Boolean] display pivot facets with an expand / collapse toggle
    # @!attribute icons
    #   @return [Hash] Icons to use for pivot facet expand + collapse

    ##
    # Query parameters:
    # @!attribute sort
    #   @return [String] the ordering of the facet field constraints; when using Solr, this is either 'count' or 'index'
    # @!attribute single
    #   @return [Boolean] whether the facet values are mutually exclusive; or, for more granular control, see tag + ex
    # @!attribute tag
    #   @return [String] See https://lucene.apache.org/solr/guide/8_6/faceting.html#tagging-and-excluding-filters
    # @!attribute ex
    #   @return [String] See https://lucene.apache.org/solr/guide/8_6/faceting.html#tagging-and-excluding-filters
    # @!attribute query
    #   @return [Hash{String => Hash}] Provides support for facet queries; the keys are mapped to user-facing parameters, and the values
    #      are a hash containing: label (a label to show the user in the facet interface), fq (a string passed into solr as an fq (when selected) or a facet.query)
    # @!attribute pivot
    #   @return []
    # @!attribute filter_query_builder
    #   @return [nil, #call] a Proc (or other object responding to #call) that receives as parameters: 1) the search builder, 2) this facet config
    #     and 3) the solr parameters hash. The Proc returns a string suitable for e.g. Solr's fq parameter, or a 2-element array of the string and a hash of additional
    #     parameters to include with the query (i.e. for referenced subqueries); note that implementations are responsible for ensuring
    #     the additional parameter keys are unique.
    # @!attribute filter_class
    #  @ return [nil, Blacklight::SearchState::FilterField] a class that implements the `FilterField`'s' API to manage URL parameters for a facet

    ##
    # Rendering:
    # @!attribute presenter
    #   @return [Blacklight::FacetFieldPresenter]
    # @!attribute component
    #   @return [Blacklight::FacetFieldListComponent]
    # @!attribute item_component
    #   @return [Blacklight::FacetItemComponent]
    # @!attribute partial
    #   @return [String] Rails view partial used to render the facet field

    extend Deprecation

    def normalize! blacklight_config = nil
      query.stringify_keys! if query

      self.collapse = true if collapse.nil?
      self.show = true if show.nil?
      self.if = show if self.if.nil?
      self.index_range = 'A'..'Z' if index_range == true
      self.presenter ||= Blacklight::FacetFieldPresenter

      if link_to_search
        Deprecation.warn(Blacklight::Configuration::FacetField, '`link_to_search:` is deprecated, use `link_to_facet:` instead')
        self.link_to_facet = link_to_search if link_to_facet.nil?
      end

      super

      if single && tag.blank? && ex.blank?
        self.tag = "#{key}_single"
        self.ex = "#{key}_single"
      end

      self
    end
  end
end
