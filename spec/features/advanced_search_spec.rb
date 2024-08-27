# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Blacklight Advanced Search Form" do
  describe "advanced search form" do
    before do
      CatalogController.blacklight_config.search_fields['all_fields']['clause_params'] = {
        edismax: {}
      }
      CatalogController.blacklight_config.search_fields['author']['clause_params'] = {
        edismax: { qf: '${author_qf}' }
      }
      CatalogController.blacklight_config.search_fields['title']['clause_params'] = {
        edismax: { qf: '${title_qf}' }
      }
      CatalogController.blacklight_config.search_fields['subject']['clause_params'] = {
        edismax: { qf: '${subject_qf}' }
      }
      visit '/catalog/advanced?hypothetical_existing_param=true&q=ignore+this+existing+query'
    end

    after do
      %w[all_fields author title subject].each do |field|
        CatalogController.blacklight_config.search_fields[field].delete(:clause_params)
      end
    end

    it "has field and facet blocks" do
      expect(page).to have_css('.query-criteria')
      expect(page).to have_css('.limit-criteria')
    end

    describe "query column" do
      it "gives the user a choice between and/or queries" do
        expect(page).to have_css('#op')
        within('#op') do
          expect(page).to have_css('option[value="must"]')
          expect(page).to have_css('option[value="should"]')
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
        expect(page).to have_css('.blacklight-language_ssim')

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
      expect(page).to have_css('article.document', count: 1)
    end

    it 'can limit to facets' do
      fill_in 'Subject', with: 'Women'
      click_on 'Language'
      check 'Urdu 3'
      click_on 'advanced-search-submit'
      expect(page).to have_content 'Pākistānī ʻaurat dorāhe par'
      expect(page).to have_no_content 'Ajikto kŭrŏk chŏrŏk sasimnikka : and 아직도　그럭　저럭　사십니까'
      expect(page).to have_css('article.document', count: 1)
    end

    it 'handles boolean queries' do
      fill_in 'All Fields', with: 'history NOT strong'
      click_on 'advanced-search-submit'
      expect(page).to have_content('Ci an zhou bian')
      expect(page).to have_no_content('Strong Medicine speaks')
      expect(page).to have_css('article.document', count: 10)
    end

    it 'handles queries in multiple fields with the ALL operator' do
      fill_in 'All Fields', with: 'history'
      fill_in 'Author', with: 'hearth'
      click_on 'advanced-search-submit'
      expect(page).to have_content('Strong Medicine speaks')
      expect(page).to have_css('article.document', count: 1)
    end

    it 'handles queries in multiple fields with the ANY operator' do
      select 'any', from: 'op'
      fill_in 'All Fields', with: 'history'
      fill_in 'Subject', with: 'women'
      click_on 'advanced-search-submit'
      expect(page).to have_content('Ci an zhou bian')
      expect(page).to have_content('Pākistānī ʻaurat dorāhe par')
      expect(page).to have_css('article.document', count: 10)
    end
  end

  describe "prepopulated advanced search form" do
    before do
      visit '/catalog/advanced?op=must&clause[1][field]=title&clause[1]query=medicine&f_inclusive[language_ssim][]=Tibetan&sort=author'
    end

    it 'prepopulates the expected fields' do
      expect(page).to have_field 'Title', with: 'medicine'
      expect(page).to have_field 'Tibetan', checked: true
      expect(page).to have_select 'op', selected: 'all'
      expect(page).to have_select 'sort', selected: 'author'
    end

    it "does not create hidden inputs for fields included in adv search form" do
      within('form.advanced') do
        expect(page).to have_no_field('clause[1][query]', type: :hidden, with: 'medicine')
        expect(page).to have_no_field('f_inclusive[language_ssim][]', type: :hidden, with: 'Tibetan')
        expect(page).to have_no_field('op', type: :hidden, with: 'must')
        expect(page).to have_no_field('sort', type: :hidden, with: 'author')
      end
    end

    it "does not have multiple parameters for a search field" do
      fill_in 'Title', with: 'bread'
      click_on 'advanced-search-submit'
      expect(page.current_url).to match(/bread/)
      expect(page.current_url).not_to match(/medicine/)
    end

    it "clears the prepopulated fields when the Start Over button is pressed" do
      expect(page).to have_field 'Title', with: 'medicine'
      expect(page).to have_field 'Tibetan', checked: true
      click_on 'Start over'
      expect(page).to have_no_field 'Title', with: 'medicine'
      expect(page).to have_no_field 'Tibetan', checked: true
    end
  end
end
