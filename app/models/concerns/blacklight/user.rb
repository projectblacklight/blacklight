# frozen_string_literal: true

module Blacklight::User
  extend ActiveSupport::Concern

  # SEE ALSO:  The lib/blacklight/generator/user_generator.rb class for where this
  # is generated into the hosting application.
  included do
    class_attribute :string_display_key, default: :email

    has_many :bookmarks, dependent: :destroy, as: :user
    has_many :searches,  dependent: :destroy, as: :user
  end

  class_methods do
    # The column that holds the user's login/identifier. Rails' authentication
    # generator uses +email_address+, while Devise and others use +email+.
    def blacklight_email_column
      column_names.include?("email_address") ? :email_address : :email
    end

    # Create a persisted "guest" user for an anonymous visitor, so they can
    # accumulate bookmarks and searches that are transferred to a real account
    # upon sign-in. Works whether the model uses +email+ or +email_address+,
    # and supplies a random password when the model authenticates with a
    # password (either +has_secure_password+'s +password_digest+ column or
    # Devise's +encrypted_password+ column).
    def create_guest_user!
      attributes = { blacklight_email_column => "guest_#{Time.current.to_i}_#{SecureRandom.hex(4)}@example.com" }

      if authenticates_with_password?
        password = SecureRandom.hex(16)
        attributes[:password] = password
        attributes[:password_confirmation] = password
      end

      create!(attributes)
    end

    # True when the model stores a password (Rails' +has_secure_password+ via
    # +password_digest+, or Devise's +database_authenticatable+ via
    # +encrypted_password+). In either case the model exposes a virtual
    # +password+ / +password_confirmation+ attribute that must be populated to
    # satisfy validation.
    def authenticates_with_password?
      column_names.intersect?(%w[password_digest encrypted_password])
    end
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
end
