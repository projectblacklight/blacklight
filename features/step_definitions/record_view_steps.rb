Then /^I (should|should not) see an? "([^\"]*)" element containing "([^\"]*)"$/ do |bool,elem,content|
  if bool == "should"
    response.should have_selector("#{elem}",:content => content)
  else
    response.should_not have_selector("#{elem}",:content => content)
  end
end

Then /^I should see link rel=alternate tags/ do
  response.should have_selector("link[rel=alternate]")
end
