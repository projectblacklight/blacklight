# frozen_string_literal: true

RSpec.describe "Search Results context", js: true do
  it "passes the current search id through" do
    search_for ''
    search_id = Search.last.id.to_s
    click_on 'Pluvial nectar of blessings'
    expect(page).to have_content "« Previous | 10 of 30 | Next »"
    prev = page.find(".pagination-search-widgets .previous")
    expect(prev['data-context-href']).to eq "/catalog/2003546302/track?counter=9&search_id=#{search_id}"

    click_on "« Previous"

    prev = page.find(".pagination-search-widgets .previous")
    expect(prev['data-context-href']).to eq "/catalog/2004310986/track?counter=8&search_id=#{search_id}"
  end

  it "redirects context urls to the original url" do
    search_for ''
    first('.index_title a').click
    expect(page).to have_content "« Previous | 1 of 30 | Next »"
    expect(page.current_url).not_to have_content "/track"
  end

  it 'shows "Back to Search" and "Start Over links"' do
    search_for 'Bod kyi naṅ chos ṅo sprod sñiṅ bsdus'
    first('.index_title a').click
    within '.constraints-container' do
      expect(page).to have_css 'a', text: 'Back to Search'
      expect(page).to have_css 'a', text: 'Start Over'
    end
  end

  context "navigating between search results using context pagination" do
    it "updates the back to search link with the current search pagination context" do
      search_for ''
      expect(page).to have_content "1 - 10"
      find_all('.index_title a').last.click
      click_on "Next »"

      click_on "Back to Search"
      expect(page).to have_content "11 - 20"
    end
  end
end

def search_for q
  visit root_path
  fill_in "q", with: q
  click_button 'search'
end
