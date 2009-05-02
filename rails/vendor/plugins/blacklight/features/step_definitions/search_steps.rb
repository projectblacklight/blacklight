# User added
Then /^I should see a search field$/ do
  response.should have_tag("input#q")
end

Then /^I should see a selectable list with field choices$/ do
  response.should have_tag("select#qt")
end

Then /^I should see a selectable list with per page choices$/ do
  response.should have_tag("select#per_page")
end

Then /^I should see a "([^\"]*)" button$/ do |label|
  response.should have_tag("input[type=?][value=?]", 'submit', label)
end

Given /^the application is configured to have searchable fields "([^\"]*)"$/ do |fields|
  labels = fields.split(", ")
  Blacklight.config[:search_fields] = []
  labels.each do |label|
    Blacklight.config[:search_fields] << [label, '']
  end
end

Then /^I should see select list "([^\"]*)" with field labels "([^\"]*)"$/ do |list_css, names|
  response.should have_tag(list_css) do
    labels = names.split(", ")
    labels.each do |label|
      with_tag('option', label)
    end
  end
end

Then /^I should see select list "([^\"]*)" with "([^\"]*)" selected$/ do |list_css, label|
  response.should have_tag(list_css) do
    with_tag('option', label, :selected => "selected")
  end
end

# Results Page
Given /^the application is configured to have sort fields "([^\"]*)"$/ do |fields|
  labels = fields.split(", ")
  Blacklight.config[:sort_fields] = []
  labels.each do |label|
    Blacklight.config[:sort_fields] << [label, '']
  end
end
