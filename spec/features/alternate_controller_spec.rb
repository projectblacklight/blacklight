# frozen_string_literal: true

RSpec.describe "Alternate Controller Behaviors" do
  it "has the correct per-page form" do
    visit search_alternate_path
    expect(page).to have_css("form[action='#{search_alternate_url}']")
    fill_in "q", with: "history"
    click_on 'search'
    expect(current_path).to match /#{search_alternate_path}/
    within "#per_page-dropdown .dropdown-menu" do
      click_on '10 per page'
    end
    expect(current_path).to match /#{search_alternate_path}/
  end

  it "has the correct search field form" do
    visit search_alternate_path
    expect(page).to have_css("form[action='#{search_alternate_url}']")
    fill_in "q", with: "history"
    click_on 'search'
    expect(current_path).to match /#{search_alternate_path}/
    click_on 'relevance'
    expect(current_path).to match /#{search_alternate_path}/
  end

  it "displays document thumbnails" do
    visit search_alternate_path
    expect(page).to have_css("form[action='#{search_alternate_url}']")
    fill_in "q", with: "history"
    click_on 'search'
    expect(page).to have_css ".document-thumbnail"
    expect(page).to have_css ".document-thumbnail a[data-context-href]"
    expect(page).to have_css ".document-thumbnail a img"
  end
end
