module Blacklight::Solr::Document::MoreLikeThis
  def more_like_this
    solr_response.more_like(self).map { |doc| SolrDocument.new(doc, solr_response) }
  end
end