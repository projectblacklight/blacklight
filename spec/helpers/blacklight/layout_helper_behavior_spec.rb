# frozen_string_literal: true

RSpec.describe Blacklight::LayoutHelperBehavior do
  describe '#show_content_classes' do
    it 'returns a string of classes' do
      expect(helper.show_content_classes).to be_an String
      expect(helper.show_content_classes).to eq 'col-lg-9 show-document'
    end
  end

  describe '#show_sidebar_classes' do
    it 'returns a string of classes' do
      expect(helper.show_sidebar_classes).to be_an String
      expect(helper.show_sidebar_classes).to eq 'page-sidebar col-lg-3'
    end
  end

  describe '#main_content_classes' do
    it 'returns a string of classes' do
      expect(helper.main_content_classes).to be_an String
      expect(helper.main_content_classes).to eq 'col-lg-9'
    end
  end

  describe '#sidebar_classes' do
    it 'returns a string of classes' do
      expect(helper.sidebar_classes).to be_an String
      expect(helper.sidebar_classes).to eq 'page-sidebar col-lg-3'
    end
  end

  describe '#container_classes' do
    before do
      allow(view).to receive(:blacklight_config).and_return(config)
    end

    context 'when not full-width' do
      let(:config) { Blacklight::Configuration.new }

      it 'returns a string of classe(s)' do
        expect(helper.container_classes).to be_an String
        expect(helper.container_classes).to eq 'container'
      end
    end

    context 'when full-width' do
      let(:config) { Blacklight::Configuration.new(full_width_layout: true) }

      it 'returns a string of classe(s)' do
        expect(helper.container_classes).to be_an String
        expect(helper.container_classes).to eq 'container-fluid'
      end
    end
  end

  describe '#html_tag_attributes' do
    before do
      allow(I18n).to receive(:locale).and_return('x')
    end

    it 'returns the current locale as the lang' do
      expect(helper.html_tag_attributes).to include lang: 'x'
    end
  end
end
