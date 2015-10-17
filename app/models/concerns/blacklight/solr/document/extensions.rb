module Blacklight::Solr::Document::Extensions
  extend ActiveSupport::Concern
  include Blacklight::Document::Extensions
  
  def self.extended(document)
    Deprecation.warn Blacklight::Solr::Document::Extensions, "Blacklight::Solr::Document::Extensions is deprecated; use Blacklight::Document::Extensions instead."
  end
end
