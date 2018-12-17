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
      raise Blacklight::Exceptions::ExpiredSessionToken
    end

    user_id
  end

  # Used for #export action with encrypted user_id, available
  # as a helper method for views.
  def encrypt_user_id(user_id, current_time = nil)
    current_time ||= Time.zone.now
    message_encryptor.encrypt_and_sign([user_id, current_time])
  end

  def export_secret_token
    secret_key_generator.generate_key('encrypted user session key')[0..(key_len - 1)]
  end

  def secret_key_generator
    @secret_key_generator ||= begin
      app = Rails.application

      secret_key_base = if app.respond_to?(:credentials)
                          # Rails 5.2+
                          app.credentials.secret_key_base
                        else
                          # Rails <= 5.1
                          app.secrets.secret_key_base
                        end
      ActiveSupport::KeyGenerator.new(secret_key_base)
    end
  end

  def message_encryptor
    ActiveSupport::MessageEncryptor.new(export_secret_token)
  end

  private

  # Ruby 2.4 requires keys of very particular lengths
  def key_len
    if ActiveSupport::MessageEncryptor.respond_to? :key_len
      ActiveSupport::MessageEncryptor.key_len
    else
     0
    end
  end
end
