# frozen_string_literal: true

# spec/support/features/session_helpers.rb
module Features
  module SessionHelpers
    def sign_up_with(email, password)
      return create_user(email: email, password: password) if respond_to?(:new_session_path)

      Capybara.exact = true
      visit new_user_registration_path
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      fill_in 'Password confirmation', with: password
      click_on 'Sign up'
    end

    def sign_in(login = 'user1')
      email = "#{login}@#{login}.com"
      create_user(email: email, password: "password")

      if respond_to?(:new_session_path)
        visit new_session_path
        fill_in("email_address", with: email)
        fill_in("password", with: "password")
      else
        visit new_user_session_path
        fill_in("user_email", with: email)
        fill_in("user_password", with: "password")
      end

      if has_button? "Sign in"
        click_on("Sign in")
      elsif has_button? "Log in"
        click_on("Log in")
      else
        raise "Unable to find sign in button"
      end
    end
  end
end
