module Blacklight
  class Configuration::SolrField < OpenStructWithHashAccess
    def normalize! blacklight_config = nil
      self.label ||= default_label
      self
    end
  
    def validate!
      raise ArgumentError.new("Must supply a solr field name") if self.field.nil?
    end

    def default_label
      if self.field.respond_to?(:titleize)
        self.field.try(:titleize)
      else
        self.field.to_s.titleize
      end
    end
  end
end

