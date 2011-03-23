When /^I follow "([^\"]*)" in "([^\"]*)"$/ do |link, scope|
  click_link_within(scope, link)
end

Then /^I should see a stylesheet/ do
  response.should have_tag("link[rel=stylesheet]")
end

Then /I should see "(.*)" (at least|at most|exactly) (.*) times?$/i do |target, comparator, expected_num|
  actual_num = response.body.split(target).length - 1
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
  actual_num = response.body.scan(/<#{target}[^>]* #{type}="#{selector}"[^>]*>/).length
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
    response.should_not have_selector("#{elem}[#{attribute}=#{value}]")
  else
    response.should have_selector("#{elem}[#{attribute}=#{value}]")
  end
end

Then /^I (should not|should) see an? "([^\"]*)" element with an? "([^\"]*)" attribute of "([^\"]*)" and an? "([^\"]*)" attribute of "([^\"]*)"$/ do |bool,elem,attribute,value,attribute2,value2|
  if bool == "should not"
    response.should_not have_selector("#{elem}[#{attribute}=#{value}][#{attribute2}=#{value2}]")
  else
    response.should have_selector("#{elem}[#{attribute}=#{value}][#{attribute2}=#{value2}]")
  end
end


