# frozen_string_literal: true

RSpec.describe 'Accessibility testing', api: false, js: true do
  it 'validates the home page' do
    visit root_path
    expect(page).to be_accessible
  end

  it 'validates the catalog page' do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'

    expect(page).to be_accessible

    within '.card.blacklight-language_ssim' do
      click_button 'Language'
      click_link "Tibetan"
    end

    expect(page).to be_accessible
  end

  it 'validates the advanced search form' do
    visit advanced_search_catalog_path
    expect(page).to be_accessible
  end

  it 'validates the single results page' do
    visit solr_document_path('2007020969')
    expect(page).to be_accessible
  end

  def be_accessible(skipping: [])
    # typeahead does funny things with the search bar
    be_axe_clean.excluding('.tt-hint').skipping(skipping + [('color-contrast' if defined?(Bootstrap) && Bootstrap::VERSION < '5')].compact)
  end
end
