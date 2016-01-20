# frozen_string_literal: true
class Bookmark < ActiveRecord::Base
  
  belongs_to :user, polymorphic: true
  belongs_to :document, polymorphic: true

  validates :user_id, presence: true

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :id, :document_id, :document_type, :title
  end

  def document
    document_type.new document_type.unique_key => document_id
  end
  
  def document_type
    value = super if defined?(super)
    value &&= value.constantize
    value ||= default_document_type
  end
  
  def default_document_type
    SolrDocument
  end
  
end
