# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Search Page" do
  it "should show welcome" do
    visit root_path
    expect(page).to have_selector("input#q")
    within ("select#search_field") do
      expect(page).to have_selector('option', text: 'All Fields')
      expect(page).to have_selector('option', text: 'Title')
      expect(page).to have_selector('option', text: 'Author')
      expect(page).to have_selector('option', text: 'Subject')
    end
    expect(page).to have_selector("button[type='submit'] .submit-search-text")
    expect(page).to_not have_selector("#startOverLink")

    expect(page).to have_content "Welcome!"
    expect(page).to have_selector("link[rel=stylesheet]")
  end

  it "should do searches across all fields" do
    visit root_path
    fill_in "q", with: 'history'
    select 'All Fields', from: 'search_field'
    click_button 'search'

    expect(page).to have_selector("link[rel=alternate][type='application/rss+xml']")
    expect(page).to have_selector("link[rel=alternate][type='application/atom+xml']")

    # opensearch
    expect(page).to have_selector("meta[name=totalResults]")
    expect(page).to have_selector("meta[name=startIndex]")
    expect(page).to have_selector("meta[name=itemsPerPage]")

    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end

    within ("select#search_field") do
      expect(page).to have_selector("option[selected]", text: "All Fields")
    end

    within ("#sortAndPerPage") do
      expect(page).to have_content "Sort by"
      expect(page).to have_content "1 - 9 of 9"
      within '#sort-dropdown' do
        expect(page).to have_link('relevance')
        expect(page).to have_link('year')
        expect(page).to have_link('author')
        expect(page).to have_link('title')
      end
    end
    within "#documents" do
      expect(page).to have_selector(".document", count: 9)
    end
  end

  it "should do searches constrained to a single field" do
    visit root_path
    fill_in "q", with: 'inmul'
    select 'Title', from: 'search_field'
    click_button 'search'

    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "Title"
      expect(page).to have_content "inmul"
    end
    within ("select#search_field") do
      expect(page).to have_selector("option[selected]", text: "Title")
    end
    within(".index_title") do
      expect(page).to have_content "1."
    end
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 to 1 of 1"
    end
  end

  it "should show vernacular (Linked 880) and call number" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within "#documents" do
      expect(page).to have_content "次按驟變"
      expect(page).to have_content "DK861.K3 V5"
    end
  end

  it "should allow you to clear the search" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end

    expect(page).to have_selector "#q[value='history']"

    click_link "Start Over"

    expect(page).to have_content "Welcome!"
    expect(page).to_not have_selector "#q[value='history']"
  end

  it "should should maintain separate search result sets when performing concurrent searches in multiple tabs/windows", :js => true do
    visit root_path
    fill_in "q", with: 'tibetan'
    click_button 'search'

    within "body" do
      expect(page).to have_content "1 - 6 of 6"
      expect(page).to have_content "Pluvial nectar of blessings"
      expect(page).to have_content "Śes yon"
    end

    visit root_path
    fill_in "q", with: 'korea'
    click_button 'search'

    within "body" do
      expect(page).to have_content "1 - 4 of 4"
      expect(page).to have_content "Koryŏ inmul yŏlchŏn"
      expect(page).to have_content "Ajikto kŭrŏk chŏrŏk sasimnikka"
    end

    #Need to simulate opening another tab by navigating directly to the update action for various pages

    item_id = '2008308175'
    last_known_search_json_string = '{"q":"tibetan","action":"index","controller":"catalog","total":6}'
    visit catalog_path(:action => 'update', :id => item_id, :method => 'put', :counter => 1, :results_view => true, :last_known_search_json_string => last_known_search_json_string) # Visit the page for the item with id `item_id` using param last_known_search_json_string `last_known_search_json_string`
    within "body" do
      expect(page).to have_content "| 1 of 6 |"
      expect(page).to have_content "Pluvial nectar of blessings"
    end
    click_link 'Next »'
    within "body" do
      expect(page).to have_content "| 2 of 6 |"
      expect(page).to have_content "Śes yon"
    end
    click_link 'Next »'
    within "body" do
      expect(page).to have_content "| 3 of 6 |"
      expect(page).to have_content "Bod kyi naṅ chos ṅo sprod sñiṅ bsdus"
    end

    item_id = '77826928'
    last_known_search_json_string = '{"q":"korea","action":"index","controller":"catalog","total":4}'
    visit catalog_path(:action => 'update', :id => item_id, :method => 'put', :counter => 1, :results_view => true, :last_known_search_json_string => last_known_search_json_string) # Visit the page for the item with id `item_id` using param last_known_search_json_string `last_known_search_json_string`
    within "body" do
      expect(page).to have_content "| 1 of 4 |"
      expect(page).to have_content "Koryŏ inmul yŏlchŏn"
    end
    click_link 'Next »'
    within "body" do
      expect(page).to have_content "| 2 of 4 |"
      expect(page).to have_content "Ajikto kŭrŏk chŏrŏk sasimnikka"
    end
    click_link 'Next »'
    within "body" do
      expect(page).to have_content "| 3 of 4 |"
      expect(page).to have_content "Pukhan pŏmnyŏngjip"
    end
  end

end

