# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Search Pagination" do
  it "should have results with pagination" do
    visit root_path
    fill_in "q", with: ''
    click_button 'search'
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 10 of "
      within '#per_page-dropdown' do
        expect(page).to have_link('10')
        expect(page).to have_link('20')
        expect(page).to have_link('50')
        expect(page).to have_link('100')
      end

    end
    click_link "Next »"
    within ("#sortAndPerPage") do
      expect(page).to have_content "11 - 20 of "
    end
    click_link "« Previous"
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 10 of "
    end
  end

  it "should be able to change the number of items per page" do
    visit root_path
    fill_in "q", with: ''
    click_button 'search'
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 10 of "
    end

    within ("#per_page-dropdown") do
      click_link '20'
    end
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 20 of "
    end
  end

  describe "when the application is configured for other per page values" do
    let!(:original_per_page) { CatalogController.blacklight_config[:per_page] }
    let!(:original_rows) { CatalogController.blacklight_config[:default_solr_params][:rows] }
    before do
      CatalogController.blacklight_config[:per_page] = [15, 30]
      CatalogController.blacklight_config[:default_solr_params][:rows] = 15
    end
    after do
      CatalogController.blacklight_config[:per_page] = original_per_page
      CatalogController.blacklight_config[:default_solr_params][:rows] = original_rows
    end
    it "should use the configured values" do
      visit root_path
      fill_in "q", with: ''
      click_button 'search'
      within ("#sortAndPerPage") do
        expect(page).to have_content "1 - 15 of "
        within '#per_page-dropdown' do
          expect(page).to have_link('15')
          expect(page).to have_link('30')
        end
      end
      within ("#per_page-dropdown") do
        click_link '30'
      end
      within ("#sortAndPerPage") do
        expect(page).to have_content "1 - 30 of "
      end
    end
  end

  it "should reset the page offset to 1 when changing per page" do
    visit root_path
    fill_in "q", with: ''
    click_button 'search'
    click_link "Next »"
    within ("#sortAndPerPage") do
      expect(page).to have_content "11 - 20 of "
    end
    within ("#per_page-dropdown") do
      click_link '20'
    end
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 20 of "
    end
  end
end
