module Blacklight
  class Configuration::SearchField < Configuration::SolrField
    def self.normalize! field_config, blacklight_config
      # Some normalization, calculate display_label from key,
      # and make sure we have a qt from defaults.             
      field_config.key = field_config.field
      field_config.label ||= field_config.key.try(:titlecase)
      field_config.qt ||= blacklight_config.default_solr_params[:qt] if blacklight_config.default_solr_params
    end
  end
end

