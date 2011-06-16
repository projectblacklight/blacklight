# -*- encoding : utf-8 -*-
# deprecated
Then /^I should see the applied filter "([^\"]*)" with the value "([^\"]*)"$/ do |filter, text|
  page.should have_selector(".facet_limit") do |node|
    node.should have_selector("h3", :content => filter)
    node.should have_selector("span.selected", :content => text)
  end
end

Then /^I should see the applied facet "([^\"]*)" with the value "([^\"]*)"$/ do |filter, text|
  page.should have_selector(".facet_limit") do |node|
    node.should have_selector("h3", :content => filter)
    node.should have_selector("span.selected", :content => text)
  end
end

Then /^I should see the facet "([^\"]*)" with the value "([^\"]*)"$/ do |filter, text|
  page.should have_selector(".facet_limit") do |node|
    node.should have_selector("h3", :content => filter)
    node.should have_selector("a.label", :content => text)
  end
end

Then /^the facet "([^\"]+)" should display$/ do |filter|
  page.should have_selector(".facet_limit") do |node|
    node.should have_selector("h3", :content => filter)
  end
end

