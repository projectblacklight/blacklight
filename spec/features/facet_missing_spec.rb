# frozen_string_literal: true

RSpec.describe "Facet missing" do
  before do
    CatalogController.blacklight_config[:default_solr_params]["facet.missing"] = true
  end

  after do
    CatalogController.blacklight_config[:default_solr_params].delete("facet.missing")
  end

  context "selecting missing field in facets" do
    it "adds facet missing query and constraints" do
      visit root_path

      within "#facet-subject_geo_ssim" do
        click_link "[Missing]"
      end

      within "#facet-subject_geo_ssim" do
        expect(page).to have_selector("span.selected", text: "[Missing")
        expect(page).to have_selector("span.facet-count.selected", text: "13")
      end

      within "#sortAndPerPage" do
        expect(page).to have_content "1 - 10 of 13"
      end

      expect(page).to have_css(".constraint-value", text: "Region")
      expect(page).to have_css(".constraint-value", text: "[Missing]")
    end
  end

  context "unselecting the facet missing facet" do
    it "unselects the missig field facet" do
      visit root_path + "?f[-subject_geo_ssim:[* TO *]][]=&f[subject_geo_ssim][]="

      within "#facet-subject_geo_ssim" do
        click_link "remove"
      end

      expect(page).not_to have_link "remove"
      expect(page).to have_content("Welcome!")
    end
  end

  context "unselecting the facet missing constraint" do
    it "unselects the missig field facet" do
      visit root_path + "?f[-subject_geo_ssim:[* TO *]][]=&f[subject_geo_ssim][]="

      within ".filter-subject_geo_ssim" do
        click_link "Remove constraint Region: [Missing]"
      end

      expect(page).not_to have_link "remove"
      expect(page).to have_content("Welcome!")
    end
  end
end
