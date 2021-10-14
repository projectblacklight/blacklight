# frozen_string_literal: true

RSpec.describe "Facets" do
  it "works without a search term" do
    visit root_path
    within "#facet-language_ssim" do
      click_link "Tibetan"
    end
    within "#sortAndPerPage" do
      expect(page).to have_content "1 - 6 of 6"
    end

    expect(page).to have_selector(".blacklight-language_ssim")
    expect(page).to have_selector(".blacklight-language_ssim.facet-limit-active")

    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "6")
    end

    click_link "India"
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 2 of 2"
    end
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "2")
    end
    within "#facet-subject_geo_ssim" do
      expect(page).to have_selector("span.selected", text: "India")
      expect(page).to have_selector("span.facet-count.selected", text: "2")
    end
  end

  it "works in conjunction with a search term" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 10 of 11"
    end

    within "#facet-language_ssim" do
      click_link "Tibetan"
    end
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 2 of 2"
    end
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "2")
    end
    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end

    click_link "2004"

    within ("#sortAndPerPage") do
      expect(page).to have_content "1 entry found"
    end
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "1")
    end
    within(".blacklight-pub_date_ssim") do
      expect(page).to have_selector("span.selected", text: "2004")
      expect(page).to have_selector("span.facet-count.selected", text: "1")
    end
  end

  it "allows removing filters" do
    visit root_path
    within "#facet-language_ssim" do
      click_link "Tibetan"
    end
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "6")
    end
    within "#facet-language_ssim" do
      click_link 'remove'
    end
    expect(page).not_to have_link 'remove'
    expect(page).to have_content('Welcome!')
  end

  it "retains filters when you change the search term" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within "#facet-language_ssim" do
      click_link 'Tibetan'
    end
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "2")
    end

    click_link '2004'

    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "1")
    end
    within(".blacklight-pub_date_ssim") do
      expect(page).to have_selector("span.selected", text: "2004")
      expect(page).to have_selector("span.facet-count.selected", text: "1")
    end
    fill_in "q", with: 'china'
    click_button 'search'

    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "1")
    end
    within(".blacklight-pub_date_ssim") do
      expect(page).to have_selector("span.selected", text: "2004")
      expect(page).to have_selector("span.facet-count.selected", text: "1")
    end
  end

  it "retains the filters when we change sort" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within "#facet-language_ssim" do
      click_link 'Tibetan'
    end
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "2")
    end
    click_link 'title'
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "2")
    end
    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end
  end

  it "retains the filters when we change per page number" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within "#facet-language_ssim" do
      click_link 'Tibetan'
    end
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "2")
    end
    within '#per_page-dropdown' do
      click_link '20'
    end
    within "#facet-language_ssim" do
      expect(page).to have_selector("span.selected", text: "Tibetan")
      expect(page).to have_selector("span.facet-count.selected", text: "2")
    end
    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end
  end

  it "is collapsed when not selected", js: true do
    visit root_path

    within(".blacklight-subject_ssim") do
      expect(page).not_to have_selector(".card-body", visible: true)
    end
  end

  it "expands when the heading button is clicked", js: true do
    visit root_path

    within(".blacklight-subject_ssim") do
      expect(page).not_to have_selector(".card-body", visible: true)
      find(".card-header button").click
      expect(page).to have_selector(".card-body", visible: true)
    end
  end

  it "expands when the button is clicked", js: true do
    visit root_path

    within(".blacklight-subject_ssim") do
      expect(page).not_to have_selector(".card-body", visible: true)
      find(".card-header").click
      expect(page).to have_selector(".card-body", visible: true)
    end
  end

  it "keeps selected facets expanded on page load", js: true do
    visit root_path

    within(".blacklight-subject_ssim") do
      page.find('h3.facet-field-heading', text: 'Topic').click
      expect(page).to have_selector(".panel-collapse", visible: true)
    end
    within(".blacklight-subject_ssim") do
      click_link "Japanese drama"
    end
    within(".blacklight-subject_ssim") do
      expect(page).to have_selector(".panel-collapse", visible: true)
    end
  end
end
