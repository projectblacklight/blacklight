# frozen_string_literal: true

describe SuggestHelper do
  before do
    allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
  end
  describe '#autocomplete_enabled?' do
    describe 'with autocomplete config' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.configure do |config|
          config.autocomplete_enabled = true
          config.autocomplete_path = 'suggest'
        end
      end
      it 'is enabled' do
        expect(helper.autocomplete_enabled?).to be true
      end
    end
    describe 'without disabled config' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.configure do |config|
          config.autocomplete_enabled = false
          config.autocomplete_path = 'suggest'
        end
      end
      it 'is disabled' do
        expect(helper.autocomplete_enabled?).to be false
      end
    end
    describe 'without path config' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.configure do |config|
          config.autocomplete_enabled = true
        end
      end
      it 'is disabled' do
        expect(helper.autocomplete_enabled?).to be false
      end
    end
  end
end