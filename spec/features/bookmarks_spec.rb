require 'spec_helper'

describe "Bookmarks" do
  describe "navigating from the homepage" do
    it "should have a link to the history page" do
      sign_in 'user1'
      visit root_path
      click_link 'Bookmarks'
      expect(page).to have_content 'You have no bookmarks'
    end
  end

  it "should clear bookmarks" do
    visit catalog_path('2007020969')
    click_button 'Bookmark'
    click_link 'Bookmarks'
    click_link 'Clear Bookmarks'
    expect(page).to have_content 'Cleared your bookmarks.'
    expect(page).to have_content 'You have no bookmarks'
  end
  it "add and remove bookmarks from search results" do
    sign_in 'user1'
    visit root_path
    fill_in "q", with: 'book'
    click_button 'search'
    click_button 'Bookmark'
    expect(page).to have_content 'Successfully added bookmark.'
    fill_in "q", with: 'book'
    click_button 'search'
    click_button 'Remove bookmark'
    expect(page).to have_content 'Successfully removed bookmark.'
  end
        
  it "should add and delete bookmarks from the show page" do
    sign_in 'user1'
    visit catalog_path('2007020969')
    click_button 'Bookmark'
    click_button 'Remove bookmark'
    expect(page).to have_content 'Successfully removed bookmark.'
  end
      
  it "should add bookmarks after a user logs in" do
    visit catalog_path('2007020969')
    click_button 'Bookmark'
    sign_in 'user1'
    visit bookmarks_path
    expect(page).to have_button("Remove bookmark")
    expect(page).to have_content("Strong Medicine speaks")
  end

  it "should cite items in bookmarks" do
    visit catalog_path('2007020969')
    click_button 'Bookmark'
    click_link 'Bookmarks'
    click_link 'Cite'
    expect(page).to have_content 'Strong Medicine speaks'
  end
  
  it "should have an endnote export" do
    visit catalog_path('2007020969')
    click_button 'Bookmark'
    visit "/bookmarks.endnote?q=" 
    expect(page).to have_content " %@ 9780743297790"
  end
  
  it "should have a refworks export" do
    visit catalog_path('2007020969')
    click_button 'Bookmark'
    visit "/bookmarks.refworks_marc_txt?q=" 
    expect(page).to have_content "LEADER 01490cam a2200361 a 4500001      2007020969"
  end
end
