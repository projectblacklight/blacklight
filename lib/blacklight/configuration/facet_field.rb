module Blacklight
  class Configuration::FacetField < Blacklight::Configuration::SolrField
    def normalize! blacklight_config         
      self.query.stringify_keys! if self.query

      if self.single and self.tag.blank? and self.ex.blank?
        self.tag = "#{self.field}_single"
        self.ex = "#{self.field}_single"
      end
      super
    end
  end
end

