# frozen_string_literal: true

RSpec.describe Blacklight::Configuration::FacetField do
  describe 'link_to_search' do
    subject { described_class.new(link_to_search: true) }

    it 'is deprecated' do
      expect(Deprecation).to receive(:warn)
      expect(subject.normalize!)
      expect(subject.link_to_facet).to eq true
    end
  end

  describe '#normalize!' do
    it 'preserves existing properties' do
      expected = double
      subject.presenter = expected

      subject.normalize!

      expect(subject.presenter).to eq expected
    end

    it 'adds a default presenter' do
      subject.normalize!

      expect(subject.presenter).to eq Blacklight::FacetFieldPresenter
    end
  end
end
