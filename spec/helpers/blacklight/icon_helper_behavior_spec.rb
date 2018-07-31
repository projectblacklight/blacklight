# frozen_string_literal: true

RSpec.describe Blacklight::IconHelperBehavior do
  describe '#blacklight_icon' do
    it 'wraps the svg in a span with classes' do
      expect(helper.blacklight_icon(:search))
        .to have_css 'span.blacklight-icons svg'
    end
  end
end
