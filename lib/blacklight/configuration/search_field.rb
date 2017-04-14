# frozen_string_literal: true

module Blacklight
  class Configuration::SearchField < Blacklight::Configuration::Field
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
