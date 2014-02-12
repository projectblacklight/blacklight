require 'spec_helper'

describe "Alternate Controller Behaviors" do
  it "should have the correct per-page form" do
    visit alternate_index_path
    page.should have_selector("form[action='#{alternate_index_url}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    expect(current_path).to match /#{alternate_index_path}/
    within "#per_page-dropdown .dropdown-menu" do
      click_on '10 per page'
    end
    expect(current_path).to match /#{alternate_index_path}/
  end

  it "should have the correct search field form" do
    visit alternate_index_path
    page.should have_selector("form[action='#{alternate_index_url}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    expect(current_path).to match /#{alternate_index_path}/
    click_on 'relevance'
    expect(current_path).to match /#{alternate_index_path}/
  end

  it "should display document thumbnails" do
    visit alternate_index_path
    page.should have_selector("form[action='#{alternate_index_url}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    expect(page).to have_selector ".document-thumbnail"
    expect(page).to have_selector ".document-thumbnail a[data-counter]"
    expect(page).to have_selector ".document-thumbnail a img"

  end
end
