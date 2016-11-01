# frozen_string_literal: true
module Blacklight::Solr::Response::MoreLikeThis
  def more_like document
    mlt = more_like_this[document.id]
    return [] unless mlt && mlt['docs']

    mlt['docs']
  end

  def more_like_this
    return {} unless self[:moreLikeThis]
        
    self[:moreLikeThis]
  end
end
