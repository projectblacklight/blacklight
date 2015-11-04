require 'spec_helper'

describe "Alternate Controller Behaviors" do
  it "should have the correct per-page form" do
    visit search_alternate_path
    expect(page).to have_selector("form[action='#{search_alternate_url}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    expect(current_path).to match /#{search_alternate_path}/
    within "#per_page-dropdown .dropdown-menu" do
      click_on '10 per page'
    end
    expect(current_path).to match /#{search_alternate_path}/
  end

  it "should have the correct search field form" do
    visit search_alternate_path
    expect(page).to have_selector("form[action='#{search_alternate_url}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    expect(current_path).to match /#{search_alternate_path}/
    click_on 'relevance'
    expect(current_path).to match /#{search_alternate_path}/
  end

  it "should display document thumbnails" do
    visit search_alternate_path
    expect(page).to have_selector("form[action='#{search_alternate_url}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    expect(page).to have_selector ".document-thumbnail"
    expect(page).to have_selector ".document-thumbnail a[data-context-href]"
    expect(page).to have_selector ".document-thumbnail a img"
  end
end
