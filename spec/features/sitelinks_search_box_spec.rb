# frozen_string_literal: true

RSpec.describe 'Sitelinks search box' do
  it 'is home page' do
    visit root_path
    expect(page).to have_selector 'script[type="application/ld+json"]', visible: :hidden
  end

  it 'on search page' do
    visit search_catalog_path q: 'book'
    expect(page).not_to have_selector 'script[type="application/ld+json"]', visible: :hidden
  end
end
