# frozen_string_literal: true
module Blacklight
  class Configuration::SearchField < Blacklight::Configuration::Field
    # @!attribute include_in_simple_select
    # @!attribute qt
    # @!attribute query_builder
    #   @return [nil, #call] a Proc (or other object responding to #call) that receives as parameters: 1) the search builder, 2) this search field,
    #     and 3) the solr_parameters hash.  The Proc returns a string suitable for e.g. Solr's q parameter, or a 2-element array of the
    #     string and a hash of additional parameters to include with the query (i.e. for referenced subqueries); note that
    #     implementations are responsible for ensuring the additional parameter keys are unique.

    def normalize! blacklight_config = nil
      self.if = include_in_simple_select if self.if.nil?

      super
      self.qt ||= blacklight_config.default_solr_params[:qt] if blacklight_config && blacklight_config.default_solr_params

      self
    end

    def validate!
      raise ArgumentError, "Must supply a search field key" if key.nil?
    end
  end
end
