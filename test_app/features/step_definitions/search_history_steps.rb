Given /^no previous searches$/ do
  # nothing to do
end

Given /^I have done a search with term "([^\"]*)"$/ do |term|
  visit catalog_index_path(:q => term)
end

