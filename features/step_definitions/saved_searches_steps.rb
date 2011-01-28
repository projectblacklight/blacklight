Given /^I am logged in as "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  user = User.create(:login => login, :email => email, :password => "password", :password_confirmation => "password")
#  visit user_sessions_path(:user_session => {:login => login, :password => "password"}), :post
#  User.find(user.id).should_not be_nil
  visit "/login" 
  fill_in("login", :with => login) 
  fill_in("password", :with => "password") 
  click_button("Login")
#  response.body.should =~ /Logged/m  

end

Given /^"([^\"]*)" has saved a search with term "([^\"]*)"$/ do |user, term|
  user = User.find_by_login(user)
  Search.create(:user_id => user.id, :query_params => {:q => term})
end



