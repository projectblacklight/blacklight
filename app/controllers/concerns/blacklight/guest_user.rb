# frozen_string_literal: true

module Blacklight
  # Provides a persisted "guest" user for anonymous visitors so they can
  # accumulate bookmarks and searches that are transferred to a real account
  # upon sign-in (see Blacklight::Controller#transfer_guest_to_user).
  #
  # This is the fallback used by Rails' built-in authentication. When Devise
  # together with the +devise-guests+ gem is used, that pair provides its own
  # +#guest_user+ / +#current_or_guest_user+ (and knows how to build a valid
  # Devise guest, e.g. skipping password validation). They sit higher in the
  # ancestor chain than this concern, so +#guest_user+ defers to +super+ when
  # available and only falls back to the implementation below otherwise. The
  # helper methods below are intentionally named to avoid colliding with
  # +devise-guests+' own +#create_guest_user+.
  module GuestUser
    extend ActiveSupport::Concern

    # Returns a persisted guest user for the current session, creating one on
    # first access. Keyed off the session so it survives across requests.
    # Returns +nil+ if a guest cannot be created (e.g. no user model).
    def guest_user
      return super if defined?(super)
      return @blacklight_guest_user if defined?(@blacklight_guest_user) && @blacklight_guest_user

      @blacklight_guest_user = find_blacklight_guest_user || create_blacklight_guest_user
    end

    private

    def find_blacklight_guest_user
      return unless (id = session[:blacklight_guest_user_id])

      blacklight_guest_user_class.find_by(id: id)
    end

    def create_blacklight_guest_user
      user = blacklight_guest_user_class.create_guest_user!
      session[:blacklight_guest_user_id] = user.id
      user
    rescue ActiveRecord::RecordInvalid
      nil
    end

    # The model class that guest users are created from. Defaults to +User+,
    # consistent with Blacklight::TokenBasedUser. Override to use another model.
    def blacklight_guest_user_class
      ::User
    end
  end
end
