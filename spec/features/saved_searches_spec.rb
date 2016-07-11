# frozen_string_literal: true

describe "Saved Searches" do
  before do
    sign_in 'user1'
    visit root_path
  end

  it "is empty" do
    click_link 'Saved Searches'
    expect(page).to have_content 'You have no saved searches'
  end

  describe "with a saved search 'book'" do
    before do
      fill_in "q", with: 'book'
      click_button 'search'
      click_link "History"
      click_button "save"
      click_link 'Saved Searches'
    end
    it "shows saved searches" do
      expect(page).to have_content 'Your saved searches'
      expect(page).to have_content 'book'
    end
    it "deletes saved searches" do
      click_button 'delete'
      expect(page).to have_content 'Successfully removed that saved search.'
    end

    describe "and a saved search 'dang'" do
      before do
        visit root_path
        fill_in "q", with: 'dang'
        click_button 'search'
        click_link "History"
        click_button "save"
        click_link 'Saved Searches'
      end
      it "clears the searhes" do
        click_link "Clear Saved Searches"
        expect(page).to have_content 'Cleared your saved searches.'
        expect(page).to have_content 'You have no saved searches'
      end
    end
  end
end
