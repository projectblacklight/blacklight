module Blacklight
  class Configuration::SearchField < Configuration::SolrField
    def normalize! blacklight_config
      # Some normalization, calculate display_label from key,
      # and make sure we have a qt from defaults.             
      self.key = self.field
      self.label ||= self.key.try(:titlecase)
      self.qt ||= blacklight_config.default_solr_params[:qt] if blacklight_config.default_solr_params
    end
  end
end

