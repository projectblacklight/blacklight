Then /^I should see an add to folder form$/ do
  response.should have_tag("form.addFolder")
end

When /^I add record (.+) to my folder$/ do |arg1|
  click_button("folder_submit_#{arg1}")
end

Given /^I have record (.+) in my folder$/ do |arg1|
  visit catalog_path(arg1)
  click_button("Add to Folder")
  click_link("Folder")
end

Then /^I (should|should not) see the Folder tools$/ do |comparator|
  case comparator
    when "should"
      response.should have_tag("ul.folderTools")
    when "should not"
      response.should_not have_tag("ul.folderTools")
    end
end 
