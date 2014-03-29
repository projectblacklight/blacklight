# -*- encoding : utf-8 -*-
module Blacklight::User
  
  extend Deprecation
  self.deprecation_horizon = 'blacklight 6.0'

  # This gives us an is_blacklight_user method that can be included in
  # the containing applications models. 
  # SEE ALSO:  The /lib/blacklight/engine.rb class for how when this 
  # is injected into the hosting application through ActiveRecord::Base extend
  def self.included(base)
    if base.respond_to? :has_many
      base.send :has_many, :bookmarks, :dependent => :destroy, :as => :user
      base.send :has_many, :searches,  :dependent => :destroy, :as => :user
    end
  end

  def bookmarks_for_documents documents = []
    if documents.length > 0
      bookmarks.where(document_type: documents.first.class.base_class, document_id: documents.map { |x| x.id})
    else
      []
    end
  end

  def bookmarked_document_ids
    Deprecation.warn self, "The User#bookmarked_document_ids method is deprecated and will be removed in Blacklight 6.0"

    self.bookmarks.pluck(:document_id)
  end

  def document_is_bookmarked?(document)
    bookmarks_for_documents([document]).any?
  end
    
  # returns a Bookmark object if there is one for document_id, else
  # nil. 
  def existing_bookmark_for(document)
    bookmarks_for_documents([document]).first
  end
end
