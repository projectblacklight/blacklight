When /^I follow "([^\"]*)" in "([^\"]*)"$/ do |link, scope|
  within(scope) do
    click_link(link)
  end
end

Then /^I should see a stylesheet/ do
  page.should have_selector("link[rel=stylesheet]")
end

