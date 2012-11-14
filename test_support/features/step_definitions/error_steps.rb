# -*- encoding : utf-8 -*-
# checkout http://blog.codefront.net/2007/03/31/testing-rescue_action_in_public-with-rspec/
Then /^I should see a flash error "([^\"]*)"$/ do |message|
  pageshould have_selector("div.notice", :text => message)
end
