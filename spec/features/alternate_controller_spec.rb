require 'spec_helper'

describe "Alternate Controller Behaviors" do
  it "should have the correct per-page form" do
    visit alternate_index_path
    expect(page).to have_selector("form[action='#{alternate_index_url}']")
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
    expect(page).to have_selector("form[action='#{alternate_index_url}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    expect(current_path).to match /#{alternate_index_path}/
    click_on 'relevance'
    expect(current_path).to match /#{alternate_index_path}/
  end

  it "should display document thumbnails" do
    visit alternate_index_path
    expect(page).to have_selector("form[action='#{alternate_index_url}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    expect(page).to have_selector ".document-thumbnail"
    expect(page).to have_selector ".document-thumbnail a[data-context-href]"
    expect(page).to have_selector ".document-thumbnail a img"

  end

  it "should have the correct order facet value links" do
    visit alternate_index_path
    within ".blacklight-example_pivot_field" do
      expect(page).to have_link("Book", :href => "http://www.example.com/alternate?f[format][]=Book")
      expect(page).to have_link("Tibetan",:href => "http://www.example.com/alternate?f[language_facet][]=Tibetan&f[format][]=Book")
      expect(page).to have_link("Hebrew", :href => "http://www.example.com/alternate?f[language_facet][]=Hebrew&f[format][]=Book")
    end
  end  
end
