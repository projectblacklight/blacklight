module Blacklight
  class Configuration::FacetField < Blacklight::Configuration::SolrField
    def normalize! blacklight_config         
      self.query.stringify_keys! if self.query
      super
    end
  end
end

