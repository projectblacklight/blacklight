# frozen_string_literal: true

RSpec.describe Blacklight::HeaderComponent, type: :component do
  before do
    with_controller_class(CatalogController) do
      allow(vc_test_controller).to receive_messages(current_user: nil, search_action_url: '/search')
      render_inline described_class.new(blacklight_config: CatalogController.blacklight_config)
    end
  end

  context 'with no slots' do
    it 'draws the topbar' do
      expect(page).to have_css 'nav.topbar'
      expect(page).to have_link 'Blacklight', href: '/'
    end
  end
end
