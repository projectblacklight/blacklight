class User < ActiveRecord::Base
  
  include SimplestAuth::Model
  
  before_create :hash_password
  
  validates_presence_of :email
  validates_uniqueness_of :email
  
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  
  validates_presence_of :login
  validates_uniqueness_of :login
  
  has_many :bookmarks
  
  def to_s; login; end
  
  def has_bookmarks?; bookmarks.count>0; end
  
  #
  # Does this user actually exist in the db?
  #
  def is_real?
    self.class.count(:conditions=>['id = ?',self.id]) == 1
  end
  
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