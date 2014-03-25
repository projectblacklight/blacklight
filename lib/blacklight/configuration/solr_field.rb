module Blacklight
  class Configuration::SolrField < OpenStructWithHashAccess
    def normalize! blacklight_config = nil
      self.label ||= default_label
      self.if = true if self.if.nil?
      self.unless = false if self.unless.nil?
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
