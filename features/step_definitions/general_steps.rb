When /^I follow "([^\"]*)" in "([^\"]*)"$/ do |link, scope|
  click_link_within(scope, link)
end

