# frozen_string_literal: true

RSpec.describe "Search History Page" do
  describe "navigating from the homepage" do
    it "has a link to the history page" do
      visit root_path
      click_on 'History'
      expect(page).to have_text 'Search History'
      expect(page).to have_text 'You have no search history'
    end
  end

  describe "when I have done a search" do
    before do
      visit root_path
      fill_in "q", with: 'book'
      click_on 'search'
      click_on 'History'
    end

    it "shows searches" do
      expect(page).to have_text 'Your recent searches'
      expect(page).to have_text 'book'
      expect(page).to have_no_text 'dang'
      visit root_path
      fill_in "q", with: 'dang'
      click_on 'search'
      click_on 'History'
      expect(page).to have_text 'book'
      expect(page).to have_text 'dang'
    end
  end

  describe "when i've done several searches" do
    before do
      visit root_path
      fill_in "q", with: 'book'
      click_on 'search'
      fill_in "q", with: 'dang'
      click_on 'search'
      click_on 'History'
    end

    it "is able to clear the history" do
      click_on "Clear Search History"
      expect(page).to have_text 'Cleared your search history.'
      expect(page).to have_text 'You have no search history'
      expect(page).to have_no_text 'book'
      expect(page).to have_no_text 'dang'
    end
  end
end
