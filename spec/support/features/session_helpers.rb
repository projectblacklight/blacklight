# spec/support/features/session_helpers.rb
module Features
  module SessionHelpers
    def sign_up_with(email, password)
      Capybara.exact = true
      visit new_user_registration_path
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      fill_in 'Password confirmation', with: password
      click_button 'Sign up'
    end

    def sign_in(login = 'user1')
      email = "#{login}@#{login}.com"
      user = User.create(:email => email, :password => "password", :password_confirmation => "password")
      visit new_user_session_path
      fill_in("user_email", :with => email)
      fill_in("user_password", :with => "password")
      click_button("Log in")
    end
  end
end
