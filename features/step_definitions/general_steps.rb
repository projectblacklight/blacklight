When /^I follow "([^\"]*)" in "([^\"]*)"$/ do |link, scope|
  click_link_within(scope, link)
end

Then /^I should see a stylesheet/ do
  response.should have_selector("link[rel=stylesheet]")
end
