# -*- encoding : utf-8 -*-
class Bookmark < ActiveRecord::Base
  
  belongs_to :user, polymorphic: true
  belongs_to :document, polymorphic: true

  validates_presence_of :user_id, :scope=>:document_id

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :id, :document_id, :document_type, :title
  end

  def document
    document_type.new document_type.unique_key => document_id
  end
  
  def document_type
    (super.constantize if defined?(super)) || default_document_type
  end
  
  def default_document_type
    SolrDocument
  end
  
end
