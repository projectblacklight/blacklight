# -*- encoding : utf-8 -*-
When /^I follow "([^\"]*)" in "([^\"]*)"$/ do |link, scope|
  within(scope) do
    click_link(link)
  end
end

Then /^I should see a stylesheet/ do
  page.should have_selector("link[rel=stylesheet]")
end

Then /I should see "(.*)" (at least|at most|exactly) (.*) times?$/i do |target, comparator, expected_num|
  actual_num = page.split(target).length - 1
  case comparator
    when "at least"
      actual_num.should >= expected_num.to_i
    when "at most"
      actual_num.should <= expected_num.to_i
    when "exactly"
      actual_num.should == expected_num.to_i
  end
end

Then /I should see a "(.*)" element with "(.*)" = "(.*)" (at least|at most|exactly) (.*) times?$/i do |target, type, selector,comparator, expected_num|
  actual_num = page.all("#{target}[#{type}=\"#{selector}\"]").length
  case comparator
    when "at least"
      actual_num.should >= expected_num.to_i
    when "at most"
      actual_num.should <= expected_num.to_i
    when "exactly"
      actual_num.should == expected_num.to_i
  end
end

Then /^I (should not|should) see an? "([^\"]*)" element with an? "([^\"]*)" attribute of "([^\"]*)"$/ do |bool,elem,attribute,value|
  if bool == "should not"
    page.should_not have_selector("#{elem}[#{attribute}=#{value}]")
  else
    page.should have_selector("#{elem}[#{attribute}=#{value}]")
  end
end

Then /^I (should not|should) see an? "([^\"]*)" element with an? "([^\"]*)" attribute of "([^\"]*)" and an? "([^\"]*)" attribute of "([^\"]*)"$/ do |bool,elem,attribute,value,attribute2,value2|
  if bool == "should not"
    page.should_not have_selector("#{elem}[#{attribute}=#{value}][#{attribute2}=#{value2}]")
  else
    page.should have_selector("#{elem}[#{attribute}=#{value}][#{attribute2}=#{value2}]")
  end
end

Then /^print the page html$/ do
  puts page.html
end
