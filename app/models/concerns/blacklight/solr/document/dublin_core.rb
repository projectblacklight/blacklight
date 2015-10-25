module Blacklight::Solr::Document::DublinCore
  include Blacklight::Document::DublinCore

  def self.extended(document)
    Deprecation.warn Blacklight::Solr::Document::DublinCore, "Blacklight::Solr::Document::DublinCore is deprecated; use Blacklight::Document::DublinCore instead."
  end
end
