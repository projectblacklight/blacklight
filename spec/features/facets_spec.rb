# frozen_string_literal: true

RSpec.describe "Facets" do
  it "shows a single facet's values" do
    visit facet_catalog_path("language_ssim")
    expect(page).to have_css ".modal-title", text: "Language"
    expect(page).to have_css ".facet-select", text: "Tibetan"
  end

  it "paginates through a facet's values" do
    visit facet_catalog_path("subject_ssim")
    expect(page).to have_css '.facet-values li:first', text: "Japanese drama"
    expect(page).to have_link "A-Z Sort"
    expect(page).to have_css '.sort-options .active', text: "Numerical Sort"
    within ".modal-footer" do
      click_on "Next »"
    end
    expect(page).to have_css '.facet-values li:first', text: "Jewish law"
    expect(page).to have_link "« Previous"
  end

  it "is able to change the facet sort" do
    visit facet_catalog_path("subject_ssim")
    expect(page).to have_css '.facet-values li:first', text: "Japanese drama"
    within ".modal-footer" do
      click_on "A-Z Sort"
    end
    expect(page).to have_css '.facet-values li:first', text: "Accident insurance"
    expect(page).to have_link "Numerical Sort"
    expect(page).to have_css '.sort-options .active', text: "A-Z Sort"
  end

  it "is able to sort more facet window by letter" do
    visit facet_catalog_path("subject_ssim")
    within ".modal-footer" do
      click_on "A-Z Sort"
    end
    expect(page).to have_css '.facet-values li:first', text: "Accident insurance"
    expect(page).to have_css '.facet-values li', count: 20
    click_on 'B'
    expect(page).to have_css '.facet-values li:first', text: "Buddhism"
    expect(page).to have_css '.facet-values li', count: 1
    click_on 'T'
    expect(page).to have_css '.facet-values li:first', text: "Teaching"
    expect(page).to have_css '.facet-values li', count: 4
    click_on 'All'
    expect(page).to have_css '.facet-values li:first', text: "Accident insurance"
    expect(page).to have_css '.facet-values li', count: 20
    find(:css, ".facet-pagination.bottom").click_on "Numerical Sort"
    expect(page).to have_css '.facet-values li:first', text: "Japanese drama"
    expect(page).to have_css '.facet-values li', count: 20
  end

  it 'is able to expand facets when javascript is enabled', :js do
    visit root_path

    expect(page).to have_css('#facet-format', visible: false)

    click_on 'Format'

    sleep(1) # let facet animation finish and wait for it to potentially re-collapse

    expect(page).to have_css('#facet-format', visible: true) # assert that it didn't re-collapse
  end

  it 'is able to expand pivot facets when javascript is enabled', :js do
    visit root_path

    click_on 'Pivot Field'

    within '#facet-example_pivot_field' do
      expect(page).to have_css('.facet-leaf-node', text: "Tibetan 6", normalize_ws: true)
      expect(page).to have_no_css('.facet-select', text: 'India')
      first('.facet-toggle-handle').click
      click_on 'India'
    end

    expect(page).to have_css('.constraint-value', text: 'Language Tibetan')
    expect(page).to have_css('.constraint-value', text: 'Region India')
  end

  describe 'heading button focus with Firefox' do
    it 'changes to the button on button click in Firefox' do
      pending 'Capybara::NotSupportedByDriverError: Capybara::Driver::Base#evaluate_script'
      visit root_path
      click_on 'Format'

      focused_element_data_target = page.evaluate_script("document.activeElement")['data-bs-target']
      expect(focused_element_data_target).to eq '#facet-format'
    end
  end

  describe '"More" links' do
    it 'has default more link with visually-hidden text' do
      visit root_path
      within '#facet-language_ssim' do
        expect(page).to have_css 'div.more_facets', text: 'more Language'
      end
    end
  end

  describe 'Facet modal content' do
    it 'allows the user to filter a long list of facet values', :js do
      visit '/catalog/facet/subject_ssim'
      expect(page).to have_no_link 'Old age' # This is on the second page of facet values
      expect(page).to have_css 'a.facet-select', count: 20

      fill_in 'facet_suggest_subject_ssim', with: "ag"

      expect(page).to have_css '.facet-suggestions'
      expect(page).to have_link 'Old age'
      expect(page).to have_css 'a.facet-select', count: 2
    end

    it 'shows the user facet suggestions that are relevant to their q param', :js do
      visit '/catalog/facet/subject_ssim?q=tibet&search_field=all_fields'
      fill_in 'facet_suggest_subject_ssim', with: 'la'

      expect(page).to have_css '.facet-suggestions'
      expect(page).to have_link 'Tibetan language'
      expect(page).to have_no_link 'Law'
      expect(page).to have_css 'a.facet-select', count: 1
    end

    it 'allows the user to toggle the sort, then filter', :js do
      visit '/catalog/facet/subject_ssim'

      fill_in 'facet_suggest_subject_ssim', with: 'po'

      expect(page).to have_css '.facet-suggestions'
      expect(page).to have_css('.facet-values li:nth-child(1)', text: 'Political plays, Japanese')
      expect(page).to have_css('.facet-values li:nth-child(2)', text: 'Military weapons')
      expect(page).to have_css('.facet-values li:nth-child(3)', text: 'Political science')

      first(:link, 'A-Z Sort').click

      expect(page).to have_css('.facet-suggest[data-facet-search-context*="facet.sort=index"]')

      fill_in 'facet_suggest_subject_ssim', with: 'po'

      expect(page).to have_css '.facet-suggestions'
      expect(page).to have_css('.facet-values li:nth-child(1)', text: 'Military weapons')
      expect(page).to have_css('.facet-values li:nth-child(2)', text: 'Political plays, Japanese')
      expect(page).to have_css('.facet-values li:nth-child(3)', text: 'Political science')
    end

    it 'allows the user to choose a starting letter, then filter', :js do
      visit '/catalog/facet/subject_ssim'

      first(:link, 'A-Z Sort').click
      expect(page).to have_css('.facet-suggest[data-facet-search-context*="facet.sort=index"]')

      click_on 'M'
      expect(page).to have_css('.facet-suggest[data-facet-search-context*="facet.prefix=M"]')

      fill_in 'facet_suggest_subject_ssim', with: 'te'

      expect(page).to have_css '.facet-suggestions'
      expect(page).to have_link 'Maternity insurance'
      expect(page).to have_no_link 'Teaching'
    end

    it 'hides previous/next links when filtering', :js do
      visit '/catalog/facet/subject_ssim'
      expect(page).to have_link 'Next »'

      fill_in 'facet_suggest_subject_ssim', with: 'te'
      expect(page).to have_css '.facet-suggestions'
      expect(page).to have_no_link 'Next »'

      fill_in 'facet_suggest_subject_ssim', with: ''
      expect(page).to have_no_css '.facet-suggestions'
      expect(page).to have_link 'Next »'
    end

    context 'when facet is configured with suggest: false' do
      before do
        enabled = CatalogController.blacklight_config.dup
        enabled.facet_fields[:subject_ssim].merge!({ suggest: false })
        allow(CatalogController).to receive(:blacklight_config).and_return enabled
      end

      it 'does not offer the user a way to filter the list of facet values' do
        visit '/catalog/facet/subject_ssim'
        expect(page).to have_no_field 'facet_suggest_subject_ssim'
      end
    end
  end

  describe 'facebook-style facet parameters' do
    it 'can perform a search' do
      visit '/?f[subject_ssim][0]=Iran.+Viza%CC%84rat-i+Kishvar'
      expect(page).to have_text 'Naqdī barā-yi tamām-i fuṣūl'
    end
  end
end
