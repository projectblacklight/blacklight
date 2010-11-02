module Blacklight::User::Authlogic
  def self.included(base)
    base.acts_as_authentic do |config|
      #config.my_config_option = my_value
      #config.transition_from_crypto_providers = Authlogic::CryptoProviders::BCrypt
    end

    base.validates_presence_of :email
    base.validates_uniqueness_of :email

    base.validates_presence_of :password, :on => :create
    base.validates_confirmation_of :password, :if => :password_changed?

    base.validates_presence_of :login
    base.validates_uniqueness_of :login

    def to_s; login; end

  end
end
