# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Search Results" do
  it "should have for an empty query" do
    visit root_path
    click_button 'search'
    number_of_results_from_page(page).should == 30
    page.should have_xpath("//a[contains(@href, #{2007020969})]")
    fill_in "q", with: 'korea'
    click_button 'search'
    number_of_results_from_page(page).should == 4
  end

  it "should find same result set with or without diacritcs" do
    visit root_path
    fill_in "q", with: 'inmul'
    click_button 'search'
    number_of_results_from_page(page).should == 1
    page.should have_xpath("//a[contains(@href, #{77826928})]")

    fill_in "q", with: 'inmül'
    click_button 'search'
    number_of_results_from_page(page).should == 1
  end
  it "should find same result set for a case-insensitive query " do
    visit root_path
    fill_in "q", with: 'inmul'
    click_button 'search'
    number_of_results_from_page(page).should == 1
    page.should have_xpath("//a[contains(@href, #{77826928})]")

    fill_in "q", with: 'INMUL'
    click_button 'search'
    number_of_results_from_page(page).should == 1
  end

  it "should order by relevancy" do
    visit root_path
    fill_in "q", with: 'Korea'
    click_button 'search'
    position_in_result_page(page, '77826928').should == 1
    position_in_result_page(page, '94120425').should == 2
    
  end

end



def position_in_result_page(page, id)
  i = -1
  page.all(".index_title a").each_with_index do |link, idx|
    i = (idx+1) if link['href'] =~ Regexp.new(Regexp.escape(id) + "$")
  end
  i.to_i
end
        
def number_of_results_for_query(query)
  visit root_path
  fill_in "q", :with => query
  click_button "search"
  get_number_of_results_from_page(page)
end

def number_of_results_from_page(page)
  page.find("meta[name=totalResults]")['content'].to_i rescue 0
end
