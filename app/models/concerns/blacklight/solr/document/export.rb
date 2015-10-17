module Blacklight::Solr::Document::Export
  include Blacklight::Document::Export
  
  def self.extended(document)
    Deprecation.warn Blacklight::Solr::Document::Export, "Blacklight::Solr::Document::Export is deprecated; use Blacklight::Document::Export instead."
  end
end
