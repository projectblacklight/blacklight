# frozen_string_literal: true

RSpec.describe Blacklight::Configuration::FacetField do
  describe '#normalize!' do
    context 'with existing properties' do
      let(:expected_presenter) { double }
      let(:expected_component) { double }

      before do
        subject.presenter = expected_presenter
        subject.component = expected_component
      end

      it 'preserves existing properties' do
        subject.normalize!

        expect(subject.presenter).to eq expected_presenter
        expect(subject.component).to eq expected_component
      end
    end

    it 'adds a default presenter and component' do
      subject.normalize!

      expect(subject.presenter).to eq Blacklight::FacetFieldPresenter
      expect(subject.component).to eq Blacklight::Facets::ListComponent
    end

    context 'when component is set to true' do
      before do
        subject.component = true
      end

      it 'casts to the default component' do
        subject.normalize!

        expect(subject.component).to eq Blacklight::Facets::ListComponent
      end
    end
  end
end
