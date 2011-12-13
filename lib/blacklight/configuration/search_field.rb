module Blacklight
  class Configuration::SearchField < OpenStructWithHashAccess
    def normalize! blacklight_config
      # Some normalization, calculate display_label from key,
      # and make sure we have a qt from defaults.             
      self.key ||= self.field
      self.field ||= self.key
      self.label ||= self.key.try(:titlecase)
      self.qt ||= blacklight_config.default_solr_params[:qt] if blacklight_config.default_solr_params
    end

    def validate!
      raise ArgumentError.new("Must supply a search field key") if self.key.nil?
    end
  end
end

