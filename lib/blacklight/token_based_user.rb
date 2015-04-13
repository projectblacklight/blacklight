module Blacklight::TokenBasedUser
  extend ActiveSupport::Concern

  included do
    helper_method :encrypt_user_id

    rescue_from Blacklight::Exceptions::ExpiredSessionToken do
      head :unauthorized
    end

  end

  protected

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
    user_id, timestamp = message_encryptor.decrypt_and_verify(encrypted_user_id)

    if timestamp < 1.hour.ago
      raise Blacklight::Exceptions::ExpiredSessionToken.new
    end

    user_id
  end

  # Used for #export action with encrypted user_id, available
  # as a helper method for views.
  def encrypt_user_id(user_id)
    message_encryptor.encrypt_and_sign([user_id, Time.now])
  end

  ##
  # This method provides Rails 3 compatibility to our message encryptor.
  # When we drop support for Rails 3, we can just use the AS::KeyGenerator
  # directly instead of this helper.
  def export_secret_token salt
    OpenSSL::PKCS5.pbkdf2_hmac_sha1(Blacklight.secret_key, salt, 1000, 64)
  end

  def message_encryptor
    derived_secret = export_secret_token("encrypted user session key")
    ActiveSupport::MessageEncryptor.new(derived_secret)
  end

end
