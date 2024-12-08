# frozen_string_literal: true

RSpec.describe 'Accessibility testing', :js, api: false do
  it 'validates the home page' do
    visit root_path
    expect(page).to be_axe_clean
  end

  it 'validates the catalog page' do
    visit root_path
    fill_in "q", with: 'history'
    click_on 'search'

    expect(page).to be_axe_clean

    within '.accordion-item.blacklight-language_ssim' do
      click_on 'Language'
      click_on "Tibetan"
    end

    expect(page).to be_axe_clean
  end

  it 'validates the advanced search form' do
    visit advanced_search_catalog_path
    expect(page).to be_axe_clean
  end

  it 'validates the single results page' do
    visit solr_document_path('2007020969')
    expect(page).to be_axe_clean
  end
end
