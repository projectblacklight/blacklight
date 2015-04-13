module Blacklight::SolrResponse::MoreLikeThis
  def more_like document
    mlt = more_like_this[document.id]
    return [] unless mlt and mlt['docs']

    mlt['docs']
  end

  def more_like_this
    return {} unless self[:moreLikeThis]
        
    self[:moreLikeThis]
  end
end
