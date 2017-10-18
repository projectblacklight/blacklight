# frozen_string_literal: true
module Blacklight::User
  # This gives us an is_blacklight_user method that can be included in
  # the containing applications models.
  # SEE ALSO:  The /lib/blacklight/engine.rb class for how when this
  # is injected into the hosting application through ActiveRecord::Base extend
  def self.included(base)
    return unless base.respond_to? :has_many
    base.send :has_many, :bookmarks, dependent: :destroy, as: :user
    base.send :has_many, :searches,  dependent: :destroy, as: :user
  end

  def bookmarks_for_documents documents = []
    if documents.any?
      bookmarks.where(document_type: documents.first.class.base_class.to_s, document_id: documents.map(&:id))
    else
      []
    end
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
