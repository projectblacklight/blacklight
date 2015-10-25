module Blacklight::Solr::Document::SchemaOrg
  include Blacklight::Document::SchemaOrg
  
  def self.extended(document)
    Deprecation.warn Blacklight::Solr::Document::SchemaOrg, "Blacklight::Solr::Document::SchemaOrg is deprecated; use Blacklight::Document::SchemaOrg instead."
  end
end
