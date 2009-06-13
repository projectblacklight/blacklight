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

Then /^I should see link "([^\"]*)"$/ do |label|
  response.should have_tag("a[href]", label)
end

Given /^the application is configured to have searchable fields "([^\"]*)" with values "([^\"]*)"$/ do |fields, values|
  labels = fields.split(", ")
  values = values.split(", ")
  combined = labels.zip(values)
  Blacklight.config[:search_fields] = []
  combined.each do |pair|
    Blacklight.config[:search_fields] << pair
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
  response.should have_tag(list_css) do |e|
    with_tag("[selected=selected]", {:count => 1}) do
      with_tag("option", {:count => 1, :text => label})
    end
  end
end

# Results Page
Given /^the application is configured to have sort fields "([^\"]*)" with values "([^\"]*)"$/ do |fields, values|
  labels = fields.split(", ")
  values = values.split(", ")
  combined = labels.zip(values)
  Blacklight.config[:sort_fields] = []
  combined.each do |pair|
    Blacklight.config[:sort_fields] << pair
  end
end

Then /^I should get results$/ do 
  response.should have_selector("div.document")
end

Then /^I should not get results$/ do 
  response.should_not have_selector("div.document")
end

