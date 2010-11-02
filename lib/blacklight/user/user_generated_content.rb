module Blacklight::User::UserGeneratedContent
  def self.included(base)
    base.has_many :bookmarks, :dependent => :destroy
    base.has_many :searches, :dependent => :destroy
  end

  def has_bookmarks?; bookmarks.count > 0; end

  def bookmarked_document_ids
    self.bookmarks.map{|bm|bm.document_id}
  end

  def document_is_bookmarked?(document_id)
    bookmarked_document_ids.include? document_id
  end

  def documents_to_bookmark=(docs)
    docs.each do |doc|
      self.bookmarks.create(doc) unless bookmarked_document_ids.include?(doc[:document_id])
    end
  end

end
