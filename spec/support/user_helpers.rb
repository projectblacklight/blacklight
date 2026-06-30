# frozen_string_literal: true

module UserHelpers
  def build_user(attributes = {})
    User.new(user_attributes(attributes))
  end

  def create_user(attributes = {})
    User.create!(user_attributes(attributes))
  end

  def user_attributes(attributes = {})
    attributes = attributes.dup
    password = attributes.delete(:password) || "password"
    email = attributes.delete(:email) || attributes.delete(:email_address) || "user@example.com"
    email_attribute = User.column_names.include?("email_address") ? :email_address : :email

    {
      email_attribute => email,
      password: password,
      password_confirmation: attributes.delete(:password_confirmation) || password
    }.merge(attributes)
  end
end
