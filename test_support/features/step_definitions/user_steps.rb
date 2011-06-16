# -*- encoding : utf-8 -*-
Given /^user with login "([^\"]*)" and email "([^\"]*)" and password "([^\"]*)"$/ do |login, email, password|
  user = User.create(:login => login, :email => email, :password => password, :password_confirmation => password)
  User.find(user.id).should_not be_nil
end
