require 'spec_helper'

describe "Facets" do
  it "should work without a search term" do
    visit root_path
    click_link "Tibetan"
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 6 of 6"
    end
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 6")
    end

    click_link "India"
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 2 of 2"
    end
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 2")
    end
    within(".blacklight-subject_geo_facet") do 
      expect(page).to have_selector("span.selected", :text => "India 2")
    end
  end

  it "should work in conjunction with a search term" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 9 of 9"
    end

    click_link "Tibetan"
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 2 of 2"
    end
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 2")
    end
    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end

    click_link "2004"

    within ("#sortAndPerPage") do
      expect(page).to have_content "1 entry found"
    end
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 1")
    end
    within(".blacklight-pub_date") do 
      expect(page).to have_selector("span.selected", :text => "2004 1")
    end
  end

  it "should allow removing filters" do
    visit root_path
    click_link "Tibetan"
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 6")
    end
    within(".blacklight-language_facet") do 
      click_link 'remove'
    end
    expect(page).to_not have_link 'remove'
    expect(page).to have_content('Welcome!')
  end

  it "should retain filters when you change the search term" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    click_link 'Tibetan'
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 2")
    end

    click_link '2004'

    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 1")
    end
    within(".blacklight-pub_date") do 
      expect(page).to have_selector("span.selected", :text => "2004 1")
    end
    fill_in "q", with: 'china'
    click_button 'search'

    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 1")
    end
    within(".blacklight-pub_date") do 
      expect(page).to have_selector("span.selected", :text => "2004 1")
    end
  end

  it "should retain the filters when we change sort" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    click_link 'Tibetan'
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 2")
    end
    click_link 'title'
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 2")
    end
    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end
  end

  it "should retain the filters when we change per page number" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    click_link 'Tibetan'
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 2")
    end
    within '#per_page-dropdown' do
      click_link '20'
    end
    within(".blacklight-language_facet") do 
      expect(page).to have_selector("span.selected", :text => "Tibetan 2")
    end
    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end
  end
end
