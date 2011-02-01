module Blacklight::User::UserGeneratedContent
  def self.included(base)
    base.has_many :bookmarks, :dependent => :destroy
    base.has_many :searches, :dependent => :destroy
  end

  def has_bookmarks?; bookmarks.count > 0; end

  def bookmarked_document_ids
    self.bookmarks.map{|bm|bm.document_id}
  end
  
  # see #current_bookmark_for, is easier
  def document_is_bookmarked?(document_id)
    bookmarked_document_ids.include? document_id
  end
  
  # returns a Bookmark object if there is one for document_id, else
  # nil. 
  def existing_bookmark_for(document_id)
    # to_a, we don't want to go to the database, we want to use cached
    # copy. 
    self.bookmarks.to_a.find {|b| b.document_id == document_id}
  end

  def documents_to_bookmark=(docs)
    docs.each do |doc|
      self.bookmarks.create(doc) unless bookmarked_document_ids.include?(doc[:document_id])
    end
  end

end
