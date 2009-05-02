Given /^I am logged in as "([^\"]*)"$/ do |user|
  email = "#{user}@#{user}.com"
  user = User.create(:login => user, :email => email, :password => "password")
  visit sessions_path(:email => email, :password => "password"), :post
  User.find(user.id).should_not be_nil
end

Given /^"([^\"]*)" has saved a search with term "([^\"]*)"$/ do |user, term|
  user = User.find_by_login(user)
  Search.create(:user_id => user.id, :query_params => {:q => term})
end



