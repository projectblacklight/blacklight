# frozen_string_literal: true

RSpec.describe 'Accessibility testing', :js, api: false do
  it 'validates the home page' do
    visit root_path
    expect(page).to be_accessible
  end

  it 'validates the catalog page' do
    visit root_path
    fill_in "q", with: 'history'
    click_on 'search'

    expect(page).to be_accessible

    within '.accordion-item.blacklight-language_ssim' do
      click_on 'Language'
      click_on "Tibetan"
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
