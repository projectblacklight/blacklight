# frozen_string_literal: true

RSpec.describe Blacklight::IconHelperBehavior do
  describe '#blacklight_icon' do
    subject(:icon) { helper.blacklight_icon(:search, classes: 'custom-class') }

    it 'returns the svg' do
      expect(icon).to have_css '.blacklight-icons svg'
    end

    it 'adds classes to the wrappering element' do
      expect(icon).to have_css '.custom-class svg'
    end

    context 'with backwards compatible arguments' do
      subject(:icon) { helper.blacklight_icon(:search, aria_hidden: true, label: 'blah') }

      it 'adds aria attributes' do
        expect(icon).to have_css '[aria-hidden="true"][aria-label="blah"]'
      end
    end
  end
end
