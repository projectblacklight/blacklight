# frozen_string_literal: true

RSpec.describe "Search Sort" do
  it "sorts on facet results with no search terms" do
    visit root_path
    page.find('summary', text: 'Language').click
    within "#facet-language_ssim" do
      click_link 'English'
    end
    expect(page).to have_content 'Sort by relevance'
    click_link 'title'
    expect(page).to have_content 'Sort by title'
  end

  it "sorts on search" do
    visit root_path
    fill_in "q", with: 'bod'
    click_button 'search'
    expect(page).to have_content 'Sort by relevance'
    click_link 'title'
    expect(page).to have_content 'Sort by title'
  end
end
