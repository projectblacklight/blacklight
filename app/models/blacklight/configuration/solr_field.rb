module Blacklight
  class Configuration::SolrField < Blacklight::Configuration::Field
    def self.extended *args
      Deprecation.warn Blacklight::Configuration::SolrField, "Blacklight::Configuration::SolrField is deprecated; use Blacklight::Configuration::Field instead"
    end
  end
end
