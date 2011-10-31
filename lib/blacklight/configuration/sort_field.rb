module Blacklight
  class Configuration::SortField < Configuration::SolrField
    def self.normalize! field_config, blacklight_config
      field_config.field ||= field_config.sort
      field_config.sort ||= field_config.field
    end

    def validate!
      raise ArgumentError.new("Must supply a solr sort string") if self.sort.nil?
    end
  end
end
