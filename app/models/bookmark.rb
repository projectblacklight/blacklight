class Bookmark < ActiveRecord::Base
  
  acts_as_taggable
  belongs_to :user
  validates_presence_of :user_id, :scope=>:document_id
  
end