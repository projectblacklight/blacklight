# frozen_string_literal: true

RSpec.describe 'Sitelinks search box' do
  it 'is home page' do
    visit root_path
    expect(page).to have_css 'script[type="application/ld+json"]', visible: :hidden
  end

  it 'on search page' do
    visit search_catalog_path q: 'book'
    expect(page).to have_no_css 'script[type="application/ld+json"]', visible: :hidden
  end
end
