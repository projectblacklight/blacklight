module Blacklight::Solr::Document::Sms
  include Blacklight::Document::Sms
  
  def self.extended(document)
    Deprecation.warn Blacklight::Solr::Document::Sms, "Blacklight::Solr::Document::Sms is deprecated; use Blacklight::Document::Sms instead."
  end
end
