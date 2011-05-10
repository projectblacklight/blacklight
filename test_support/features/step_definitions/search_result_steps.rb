#include Blacklight::SolrHelper

When /^I fill in the search box with "(.*?)"$/ do |query|
  query.gsub!(/\\"/, '"')
  fill_in(:q, :with => query)
end


Then /^I should get (at least|at most|exactly) (\d+) results?$/i do |comparator, comparison_num|
  number_of_records = get_number_of_results_from_page(page)

  case comparator
    when "at least"
      number_of_records.should >= comparison_num.to_i
    when "at most"
      number_of_records.should <= comparison_num.to_i
    when "exactly"  
      number_of_records.should == comparison_num.to_i
  end
end


Then /^I should have (the same number of|fewer|more) results (?:than|as) a(?:n?) search for "(.*)"$/i do |comparator, query|
  query.gsub!(/\\"/, '"')
  number_of_records = get_number_of_results_from_page(page)

  case comparator
    when "the same number of"
      get_number_of_results_for_query(query).should == number_of_records
   when "fewer"
      get_number_of_results_for_query(query).should > number_of_records
    when "fewer"
      get_number_of_results_for_query(query).should < number_of_records
  end
end

Then /^I should get id "([^\"]+)" in the results$/i do |id|
  page.should have_xpath("//a[contains(@href, #{id})]")
end

Then /^I should not get id "([^\"]+)" in the results$/i do |id|
  page.should_not have_xpath("//a[contains(@href, #{id})]")
end

Then /^I should get id "([^\"]+)" in the first (\d+) results?$/i do |id, max_num|
  pos = get_position_in_result_page(page, id)
  pos.should_not == -1
  pos.should < max_num.to_i
end

Then /^I should not get id "([^\"]+)" in the first (\d+) results?$/i do |id, max_num|
  pos = get_position_in_result_page(page, id)
  pos.should_not == -1

  if pos > 0
    pos.should >= max_num.to_i 
  else
    pos.should == -1 if pos == -1 
  end
end

Then /^I should get id "([^\"]+)" before id "([^\"]+)"$/i do |id1, id2|
  pos1 = get_position_in_result_page(page, id1)
  pos2 = get_position_in_result_page(page, id2)
  pos1.should_not == -1
  pos2.should_not == -1

  pos1.should < pos2
end

Then /^I should get id "([^\"]+)" and id "([^\"]+)" no more than (\d+) positions? from each other$/i do |id1, id2, limit|

  pos1 = get_position_in_result_page(page, id1)
  pos2 = get_position_in_result_page(page, id2)
  pos1.should_not == -1
  pos2.should_not == -1

  (pos1 - pos2).abs.should <= limit.to_i
end

Then /^I should get at least (\d+) of these ids in the first (\d+) results: "([^\"]+)"$/i do |how_many, limit, id_string|
  id_string.split(/,/).select do |id|
    pos = get_position_in_result_page(page, id)
    pos != -1 and pos < limit.to_i
  end.length.should >= how_many.to_i 
end

Then /^I (should not|should) see an? "([^\"]*)" element with an? "([^\"]*)" attribute of "([^\"]*)"$/ do |bool,elem,attribute,value|
  if bool == "should not"
    page.should_not have_selector("#{elem}[#{attribute}=#{value}]")
  else
    page.should have_selector("#{elem}[#{attribute}=#{value}]")
  end
end

def get_position_in_result_page(page, id)
  i = -1
  page.all(".index_title a").each_with_index do |link, idx|
    i = (idx+1) if link['href'] =~ Regexp.new(Regexp.escape(id) + "$")
  end
  i.to_i
end

def get_number_of_results_for_query(query)
  visit root_path
  fill_in "q", :with => query
  click_button "search"
  get_number_of_results_from_page(page)
end

def get_number_of_results_from_page(page)
  page.find("meta[name=totalResults]")['content'].to_i rescue 0
end
