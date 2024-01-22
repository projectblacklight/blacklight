# frozen_string_literal: true

module Blacklight::TokenBasedUser
  extend ActiveSupport::Concern

  included do
    if respond_to? :helper_method
      helper_method :encrypt_user_id
    end

    rescue_from Blacklight::Exceptions::ExpiredSessionToken do
      head :unauthorized
    end
  end

  private

  def token_or_current_or_guest_user
    token_user || current_or_guest_user
  end

  def token_user
    @token_user ||= if params[:encrypted_user_id]
                      user_id = decrypt_user_id params[:encrypted_user_id]
                      User.find(user_id)
                    end
  end

  # Used for #export action, with encrypted user_id.
  def decrypt_user_id(encrypted_user_id)
    user_id, timestamp = Rails::Secrets.decrypt(encrypted_user_id)

    if timestamp < 1.hour.ago
      raise Blacklight::Exceptions::ExpiredSessionToken
    end

    user_id
  end

  # Used for #export action with encrypted user_id, available
  # as a helper method for views.
  def encrypt_user_id(user_id, current_time = nil)
    current_time ||= Time.zone.now
    Rails::Secrets.encrypt([user_id, current_time])
  end
end
