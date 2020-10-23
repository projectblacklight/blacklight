# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Blacklight Advanced Search Form" do
  describe "advanced search form" do
    before do
      visit '/catalog/advanced?hypothetical_existing_param=true&q=ignore+this+existing+query'
    end

    it "has field and facet blocks" do
      expect(page).to have_selector('.query-criteria')
      expect(page).to have_selector('.limit-criteria')
    end

    describe "query column" do
      it "gives the user a choice between and/or queries" do
        expect(page).to have_selector('#op')
        within('#op') do
          expect(page).to have_selector('option[value="must"]')
          expect(page).to have_selector('option[value="should"]')
        end
      end

      it "lists the configured search fields" do
        expect(page).to have_field 'All Fields'
        expect(page).to have_field 'Title'
        expect(page).to have_field 'Author'
        expect(page).to have_field 'Subject'
      end
    end

    describe "facet column" do
      it "lists facets" do
        expect(page).to have_selector('.blacklight-language_ssim')

        within('.blacklight-language_ssim') do
          expect(page).to have_content 'Language'
        end
      end
    end

    it 'scopes searches to fields' do
      fill_in 'Title', with: 'Medicine'
      click_on 'advanced-search-submit'
      expect(page).to have_content 'Remove constraint Title: Medicine'
      expect(page).to have_content 'Strong Medicine speaks'
    end
  end

  describe "prepopulated advanced search form" do
    before do
      visit '/catalog/advanced?op=must&clause[0][field]=title&clause[0]query=medicine'
    end

    it "does not create hidden inputs for search fields" do
      expect(page).to have_field 'Title', with: 'medicine'
    end

    it "does not have multiple parameters for a search field" do
      fill_in 'Title', with: 'bread'
      click_on 'advanced-search-submit'
      expect(page.current_url).to match(/bread/)
      expect(page.current_url).not_to match(/medicine/)
    end
  end
end
