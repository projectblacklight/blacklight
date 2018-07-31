# frozen_string_literal: true

describe 'Sitelinks search box' do
  it 'is home page' do
    visit root_path
    expect(page).to have_css 'script[type="application/ld+json"]'
  end
  it 'on search page' do
    visit search_catalog_path q: 'book'
    expect(page).not_to have_css 'script[type="application/ld+json"]'
  end
end
