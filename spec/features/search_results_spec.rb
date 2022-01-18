# frozen_string_literal: true

RSpec.describe "Search Results" do
  it "has for an empty query" do
    search_for ''
    expect(number_of_results_from_page(page)).to eq 30
    expect(page).to have_xpath("//a[contains(@href, 2007020969)]")
    search_for 'korea'
    expect(number_of_results_from_page(page)).to eq 4
  end

  it "finds same result set with or without diacritcs" do
    search_for 'inmul'
    expect(number_of_results_from_page(page)).to eq 1
    expect(page).to have_xpath("//a[contains(@href, 77826928)]")

    search_for 'inmül'
    expect(number_of_results_from_page(page)).to eq 1
  end

  it "finds same result set for a case-insensitive query" do
    search_for 'inmul'
    expect(number_of_results_from_page(page)).to eq 1
    expect(page).to have_xpath("//a[contains(@href, 77826928)]")

    search_for 'INMUL'
    expect(number_of_results_from_page(page)).to eq 1
  end

  it "orders by relevancy" do
    search_for "Korea"
    expect(position_in_result_page(page, '77826928')).to eq 1
    expect(position_in_result_page(page, '94120425')).to eq 4
  end

  it "has an opensearch description document" do
    visit root_path
    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    expect(page).to have_xpath("//link[contains(@rel, 'search')]")
    expect(page.find(:xpath, "//link[contains(@rel, 'search')]")[:href]).to eq "http://www.example.com/catalog/opensearch.xml"
    Capybara.ignore_hidden_elements = tmp_value
  end

  it "provides search hints if there are no results" do
    search_for 'asdfghj'
    expect(page).to have_content "No results found for your search"
  end

  it "provides search hints if there are no results" do
    visit root_path
    fill_in "q", with: "inmul"
    select "Author", from: "search_field"
    click_button 'search'
    expect(page).to have_content "No results found for your search"
    expect(page).to have_content "you searched by Author"
    click_on "try searching everything"
    expect(page).to have_xpath("//a[contains(@href, 77826928)]")
  end
end
