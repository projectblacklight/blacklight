module Blacklight
  class Configuration::SearchField < Blacklight::Configuration::Field
    def normalize! blacklight_config = nil
      self.if = self.include_in_simple_select if self.if.nil?

      super
      self.qt ||= blacklight_config.default_solr_params[:qt] if blacklight_config && blacklight_config.default_solr_params

      self
    end

    def validate!
      raise ArgumentError.new("Must supply a search field key") if self.key.nil?
    end
  end
end
