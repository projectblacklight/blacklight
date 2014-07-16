# -*- encoding : utf-8 -*-

require 'spec_helper'

describe "Search Results" do
  it "should have for an empty query" do
    search_for ''
    expect(number_of_results_from_page(page)).to eq 30
    expect(page).to have_xpath("//a[contains(@href, #{2007020969})]")
    search_for 'korea'
    expect(number_of_results_from_page(page)).to eq 4
  end

  it "should find same result set with or without diacritcs" do
    search_for 'inmul'
    expect(number_of_results_from_page(page)).to eq 1
    expect(page).to have_xpath("//a[contains(@href, #{77826928})]")

    search_for 'inmül'
    expect(number_of_results_from_page(page)).to eq 1
  end
  it "should find same result set for a case-insensitive query " do
    search_for 'inmul'
    expect(number_of_results_from_page(page)).to eq 1
    expect(page).to have_xpath("//a[contains(@href, #{77826928})]")

    search_for 'INMUL'
    expect(number_of_results_from_page(page)).to eq 1
  end

  it "should order by relevancy" do
    search_for "Korea"
    expect(position_in_result_page(page, '77826928')).to eq 1
    expect(position_in_result_page(page, '94120425')).to eq 2
    
  end

  it "should have an opensearch description document" do
    visit root_path
    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    expect(page).to have_xpath("//link[contains(@rel, 'search')]")
    expect(page.find(:xpath, "//link[contains(@rel, 'search')]")[:href]).to eq "http://www.example.com/catalog/opensearch.xml"
    Capybara.ignore_hidden_elements = tmp_value
  end

  it "should provide search hints if there are no results" do
    search_for 'asdfghj'
    expect(page).to have_content "No results found for your search"
  end
end


def search_for q
  visit root_path
  fill_in "q", with: q
  click_button 'search'
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
  tmp_value = Capybara.ignore_hidden_elements
  Capybara.ignore_hidden_elements = false
  val = page.find("meta[name=totalResults]")['content'].to_i rescue 0
  Capybara.ignore_hidden_elements = tmp_value
  val
end
