# -*- encoding : utf-8 -*-
class Bookmark < ActiveRecord::Base
  
  belongs_to :user
  validates_presence_of :user_id, :scope=>:document_id
  attr_accessible :id, :document_id, :title


  def document
    SolrDocument.new :id => document_id
  end
  
end
