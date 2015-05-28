require 'spec_helper'

describe "/catalog/_save_search.html.erb" do
  describe 'a current user' do
    before do
      sign_in 'user1'
    end
    describe ' and a saved search' do
      it 'renders a forget button' do
        assign(:current_search_session, double('saved?' => true, id: 1))
        render
        within 'form[action="/saved_searches/forget/1"]' do
          expect(rendered).to have_css 'input[value="forget"]'
        end
      end
    end
    describe ' and a search that is not saved' do
      it 'renders a save button' do
        assign(:current_search_session, double('saved?' => false, id: 1))
        render
        within 'form[action="/saved_searches/save/1"]' do
          expect(rendered).to have_css 'input[value="save"]'
        end
      end
    end
  end
  describe 'no current user and search that is not saved' do
    it 'renders a save button' do
      assign(:current_search_session, double('saved?' => false, id: 1))
      render
      within 'form[action="/saved_searches/save/1"]' do
        expect(rendered).to have_css 'input[value="save"]'
      end
    end
  end
  describe 'no current search' do
    it 'renders nothing' do
      assign(:current_search_session, false)
      render
      expect(rendered).to_not have_css 'form'
    end
  end
end
