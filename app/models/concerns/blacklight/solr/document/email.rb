module Blacklight::Solr::Document::Email
  include Blacklight::Document::Email
  
  def self.extended(document)
    Deprecation.warn Blacklight::Solr::Document::Email, "Blacklight::Solr::Document::Email is deprecated; use Blacklight::Document::Email instead."
  end
end
