module Blacklight
  class Configuration::SolrField < OpenStructWithHashAccess
    def self.normalize!(field_config, blacklight_config)
      field_config.label ||= field_config.field.try(:titleize)
    end

    def normalize! *args
      self.class.normalize! self, *args
    end
  
    def validate!
      raise ArgumentError.new("Must supply a solr field name") if self.field.nil?
    end
  end
end

