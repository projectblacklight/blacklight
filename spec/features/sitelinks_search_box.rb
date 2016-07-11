# frozen_string_literal: true

feature 'Sitelinks search box' do
  scenario 'is home page' do
    visit root_path
    expect(page).to have_css 'script[type="application/ld+json"]'
  end
  scenario 'on search page' do
    visit search_catalog_path q: 'book'
    expect(page).to_not have_css 'script[type="application/ld+json"]'
  end
end
