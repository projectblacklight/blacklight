class SolrDocument
  
  include Blacklight::Solr::Document
  include Blacklight::Solr::Document::Marc
  include Blacklight::Solr::Document::EAD
  
end