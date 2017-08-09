# frozen_string_literal: true

RSpec.describe "Search History Page" do
  describe "navigating from the homepage" do
    it "has a link to the history page" do
      visit root_path
      click_link 'History'
      expect(page).to have_content 'Search History'
      expect(page).to have_content 'You have no search history'
    end
  end

  describe "when I have done a search" do
    before do
      visit root_path
      fill_in "q", with: 'book'
      click_button 'search'
      click_link 'History'
    end
    it "shows searches" do
      expect(page).to have_content 'Your recent searches'
      expect(page).to have_content 'book'
      expect(page).to_not have_content 'dang'
      visit root_path
      fill_in "q", with: 'dang'
      click_button 'search'
      click_link 'History'
      expect(page).to have_content 'book'
      expect(page).to have_content 'dang'
    end
  end

  describe "when i've done several searches" do
    before do
      visit root_path
      fill_in "q", with: 'book'
      click_button 'search'
      fill_in "q", with: 'dang'
      click_button 'search'
      click_link 'History'
    end
    it "is able to clear the history" do
      click_link "Clear Search History"
      expect(page).to have_content 'Cleared your search history.'
      expect(page).to have_content 'You have no search history'
      expect(page).to_not have_content 'book'
      expect(page).to_not have_content 'dang'
    end
  end
end
