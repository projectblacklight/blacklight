Then /^I should see an add to folder form$/ do
  page.should have_selector("form.addFolder")
end

Then /^I should see a remove from folder form$/ do
  page.should have_selector("form.deleteFolder")
end

When /^I (add|remove) record (.+) (to|from) my folder$/ do |add_or_remove, id, wording|
  click_button("folder_submit_#{id}")
end

Given /^I have record (.+) in my folder$/ do |arg1|
  visit catalog_path(arg1)
  click_button("Add to folder")
  click_link("Folder")
end

Then /^I (should|should not) see the Folder tools$/ do |comparator|
  case comparator
    when "should"
      page.should have_selector("ul.folderTools")
    when "should not"
      page.should_not have_selector("ul.folderTools")
    end
end 
