# frozen_string_literal: true

RSpec.describe Blacklight::IconHelperBehavior do
  describe '#blacklight_icon' do
    subject(:icon) { helper.blacklight_icon(:search) }

    it 'returns the svg' do
      expect(icon).to have_css 'svg'
    end
  end
end
