# -*- encoding : utf-8 -*-

When /^I visit the page for the item with id "([^\"]*)" using param last_known_search_json_string = '([^\']*)'$/ do |item_id, last_known_search_json_string|
  visit catalog_path(:action => 'update', :id => item_id, :method => 'put', :counter => 1, :results_view => true, :last_known_search_json_string => last_known_search_json_string)
end

When /^(?:|I )follow the Next » link$/ do
  click_link('Next »')
end
