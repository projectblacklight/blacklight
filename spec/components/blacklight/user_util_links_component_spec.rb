# frozen_string_literal: true

RSpec.describe Blacklight::UserUtilLinksComponent, type: :component do
  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }

  before do
    with_controller_class(CatalogController) do
      allow(vc_test_controller).to receive_messages(current_user: nil, current_or_guest_user: nil)
      render_inline described_class.new(blacklight_config: blacklight_config)
    end
  end

  it 'renders the nav actions and the theme switcher' do
    expect(page).to have_css 'ul.navbar-nav'
    expect(page).to have_link 'History'
    expect(page).to have_css '.nav-item .vr'
  end

  context 'with dark mode support disabled' do
    let(:blacklight_config) do
      CatalogController.blacklight_config.deep_copy.tap { |config| config.dark_mode_support = false }
    end

    it 'does not render the theme switcher' do
      expect(page).to have_no_css '.nav-item .vr'
    end
  end
end
