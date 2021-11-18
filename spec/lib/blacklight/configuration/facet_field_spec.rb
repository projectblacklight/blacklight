# frozen_string_literal: true

RSpec.describe Blacklight::Configuration::FacetField do
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

    it 'adds a default component' do
      subject.normalize!

      expect(subject.component).to eq Blacklight::FacetFieldListComponent
    end

    it 'adds a default component when the component is set to true' do
      subject.component = true

      subject.normalize!

      expect(subject.component).to eq Blacklight::FacetFieldListComponent
    end
  end
end
