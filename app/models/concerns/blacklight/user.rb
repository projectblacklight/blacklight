# frozen_string_literal: true

module Blacklight::User
  extend ActiveSupport::Concern
  # SEE ALSO:  The lib/blacklight/generator/user_generator.rb class for where this
  # is generated into the hosting application.
  included do
    has_many :bookmarks, dependent: :destroy, as: :user
    has_many :searches,  dependent: :destroy, as: :user
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

  ##
  # @return [String] a user-displayable login/identifier for the user account
  def to_s
    string_display_key = self.class.string_display_key
    return send(string_display_key) if respond_to?(string_display_key)

    super
  end

  module ClassMethods
    def string_display_key(attr_name = nil)
      return @string_display_key if attr_name.blank?

      @string_display_key = attr_name
    end

    def string_display_key_unless(attr_name)
      @string_display_key || string_display_key(attr_name)
    end
  end
end
