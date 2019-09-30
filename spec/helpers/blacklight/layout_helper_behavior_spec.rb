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
    it 'returns a string of classe(s)' do
      expect(helper.container_classes).to be_an String
      expect(helper.container_classes).to eq 'container'
    end
  end
end
