# frozen_string_literal: true

RSpec.describe "Search Sort" do
  it "sorts on facet results with no search terms" do
    visit root_path
    within "#facet-language_ssim" do
      click_on 'English'
    end
    expect(page).to have_content 'Sort by relevance'
    click_on 'title'
    expect(page).to have_content 'Sort by title'
  end

  it "sorts on search" do
    visit root_path
    fill_in "q", with: 'bod'
    click_on 'search'
    expect(page).to have_content 'Sort by relevance'
    click_on 'title'
    expect(page).to have_content 'Sort by title'
  end
end
