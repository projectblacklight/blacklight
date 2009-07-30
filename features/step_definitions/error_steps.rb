Then /^I should see a flash error "([^\"]*)"$/ do |message|
  response.should have_tag("div.notice", :text => message)
end
