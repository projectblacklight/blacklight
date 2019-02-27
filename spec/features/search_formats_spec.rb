# frozen_string_literal: true

RSpec.describe "Search Formats" do
  it "has an RSS XML response" do
    visit "/catalog.rss?q="
    expect(page).to have_content "Blacklight Search Results"
    expect(page).to have_xpath('//item', count: 10)
  end

  it "has an ATOM XML response" do
    visit "/catalog.atom?q="
    expect(page).to have_content "Blacklight Search Results"

    expect(page).to have_xpath('//entry', count: 10)
  end
end
