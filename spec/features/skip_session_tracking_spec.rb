# frozen_string_literal: true

RSpec.describe 'Search session skipping' do
  describe 'crawler search' do
    let(:original_proc) { ::CatalogController.blacklight_config.skip_session_tracking }

    before do
      ::CatalogController.blacklight_config.skip_session_tracking = ->(req, params) { params.fetch('view', nil) == 'weird_json_view' }
    end

    after do
      ::CatalogController.blacklight_config.skip_session_tracking = original_proc
    end

    it 'remembers most searches' do
      visit root_path
      fill_in 'q', with: 'chicken'
      expect { click_button 'search' }.to change(Search, :count).by(1)
    end

    it 'does not remember weird json search' do
      visit root_path
      expect { visit search_catalog_path(q: 'chicken', view: 'weird_json_view') }.not_to change(Search, :count)
    end
  end
end
