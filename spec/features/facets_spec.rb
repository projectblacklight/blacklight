# frozen_string_literal: true

RSpec.describe "Facets" do
  it "shows a single facet's values" do
    visit facet_catalog_path("language_ssim")
    expect(page).to have_selector ".modal-title", text: "Language"
    expect(page).to have_selector ".facet-select", text: "Tibetan"
  end

  it "paginates through a facet's values" do
    visit facet_catalog_path("subject_ssim")
    expect(page).to have_selector '.facet-values li:first', text: "Japanese drama"
    expect(page).to have_link "A-Z Sort"
    expect(page).to have_selector '.sort-options .active', text: "Numerical Sort"
    within ".modal-footer" do
      click_on "Next »"
    end
    expect(page).to have_selector '.facet-values li:first', text: "Jewish law"
    expect(page).to have_link "« Previous"
  end

  it "is able to change the facet sort" do
    visit facet_catalog_path("subject_ssim")
    expect(page).to have_selector '.facet-values li:first', text: "Japanese drama"
    within ".modal-footer" do
      click_on "A-Z Sort"
    end
    expect(page).to have_selector '.facet-values li:first', text: "Accident insurance"
    expect(page).to have_link "Numerical Sort"
    expect(page).to have_selector '.sort-options .active', text: "A-Z Sort"
  end

  it "is able to sort more facet window by letter" do
    visit facet_catalog_path("subject_ssim")
    within ".modal-footer" do
      click_on "A-Z Sort"
    end
    expect(page).to have_selector '.facet-values li:first', text: "Accident insurance"
    expect(page).to have_css '.facet-values li', count: 20
    click_on 'B'
    expect(page).to have_selector '.facet-values li:first', text: "Buddhism"
    expect(page).to have_css '.facet-values li', count: 1
    click_on 'T'
    expect(page).to have_selector '.facet-values li:first', text: "Teaching"
    expect(page).to have_css '.facet-values li', count: 4
    click_on 'All'
    expect(page).to have_selector '.facet-values li:first', text: "Accident insurance"
    expect(page).to have_css '.facet-values li', count: 20
    find(:css, ".facet-pagination.bottom").click_on "Numerical Sort"
    expect(page).to have_selector '.facet-values li:first', text: "Japanese drama"
    expect(page).to have_css '.facet-values li', count: 20
  end

  it 'is able to expand facets when javascript is enabled', js: true do
    visit root_path

    expect(page).to have_css('#facet-format', visible: false)

    page.find('h3.facet-field-heading a', text: 'Format').click

    sleep(1) # let facet animation finish and wait for it to potentially re-collapse

    expect(page).to have_css('#facet-format', visible: true) # assert that it didn't re-collapse
  end

  describe '"More" links' do
    it 'has default more link with sr-only text' do
      visit root_path
      within '#facet-language_ssim' do
        expect(page).to have_css 'li.more_facets', text: 'more Language'
      end
    end
  end
end
