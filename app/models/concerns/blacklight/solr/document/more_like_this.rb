# frozen_string_literal: true
module Blacklight::Solr::Document::MoreLikeThis
  def more_like_this
    response.more_like(self).map { |doc| self.class.new(doc, response) }
  end
end
