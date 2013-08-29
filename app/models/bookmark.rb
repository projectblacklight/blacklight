# -*- encoding : utf-8 -*-
class Bookmark < ActiveRecord::Base
  
  belongs_to :user
  validates_presence_of :user_id, :scope=>:document_id
  attr_accessible :id, :document_id, :title if Rails::VERSION::MAJOR < 4


  def document
    SolrDocument.new SolrDocument.unique_key => document_id
  end
  
end
