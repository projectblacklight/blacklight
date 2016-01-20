# frozen_string_literal: true
require 'spec_helper'

describe "Search History Page" do
  describe "navigating from the homepage" do
    it "should have a link to the history page" do
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
    it "should show searches" do
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
    it "should be able to clear the history" do
      click_link "Clear Search History"
      expect(page).to have_content 'Cleared your search history.'
      expect(page).to have_content 'You have no search history'
      expect(page).to_not have_content 'book'
      expect(page).to_not have_content 'dang'
    end
  end

  describe "when logged in" do
    before do
      sign_in 'user1'
      fill_in "q", with: 'book'
      click_button 'search'
      click_link 'History'
    end

    it "should save and forget the search" do
      click_button 'save'
      expect(page).to have_content 'Successfully saved your search.'
      click_button 'forget'
      expect(page).to have_content 'Successfully removed that saved search.'
      expect(page).to have_button 'save'
    end

    it "should not show results after logging out" do
      click_button 'save'
      expect(page).to have_content 'Successfully saved your search.'
      click_link 'Log Out'
      click_link 'History'
      expect(page).to_not have_content 'book'
    end
  end
end
