# -*- encoding : utf-8 -*-
Given /^the application is configured to have per page with values "([^\"]*)"$/ do |values|
  values = values.split(", ")
  CatalogController.blacklight_config[:per_page] = []
  values.each do |value|
    CatalogController.blacklight_config[:per_page] << value
  end
  CatalogController.blacklight_config[:default_solr_params][:rows] = values[0]
end


Then /^I should see a selectable list with per page choices$/ do
  page.should have_selector("#per_page-dropdown")
end

Then /^I should see the per_page dropdown with values "(.*?)"$/ do |arg1|
  page.should have_selector('#per_page-dropdown') do
    labels = values.split(", ")
    labels.each do |label|
      with_tag('li', label)
    end
  end
end

When /^I show (\d+) per page$/ do |value|
  within('#per_page-dropdown .css-dropdown ul') do
    click_link("#{value} per page")
  end
end
