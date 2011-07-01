# -*- encoding : utf-8 -*-
Given /^I am logged in as "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  user = User.create(:login => login, :email => email, :password => "password", :password_confirmation => "password")
#  visit user_sessions_path(:user_session => {:login => login, :password => "password"}), :post
#  User.find(user.id).should_not be_nil
  visit new_user_session_path
  fill_in("user_email", :with => email) 
  fill_in("user_password", :with => "password") 
  click_button("Sign in")
#  response.body.should =~ /Logged/m  
  Then 'I should see "Log Out"'
end

Given /^"([^\"]*)" has saved a search with term "([^\"]*)"$/ do |user, term|
  user = User.find_by_email("#{user}@#{user}.com")
  user.searches << Search.create(:query_params => {:q => term})
  user.save!
end



