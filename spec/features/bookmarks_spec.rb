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
    pending "https://github.com/projectblacklight/blacklight/issues/590 bad test"
    visit catalog_path('2007020969')
    click_button 'Bookmark'
    sign_in 'user1'
    visit bookmarks_path
    # click_link 'Bookmarks'
    expect(page).to have_button("Remove bookmark")
  end

  it "should cite items in bookmarks" do
    visit catalog_path('2007020969')
    click_button 'Bookmark'
    click_link 'Bookmarks'
    click_link 'Cite'
    expect(page).to have_content 'Strong Medicine speaks'
  end
end
