# -*- encoding : utf-8 -*-
Then /^I (should|should not) see an? "([^\"]*)" element containing "([^\"]*)"$/ do |bool,elem,content|
  if bool == "should"
    page.should have_xpath("//#{elem}[text()='#{content}']")
  else
    page.should have_no_xpath("//#{elem}[text()='#{content}']")
  end
end  

Then /^I should see link rel=alternate tags/ do
  page.should have_selector("link[rel=alternate]")
end
