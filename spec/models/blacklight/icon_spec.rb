RSpec.describe Blacklight::Icon do
  subject { described_class.new(:search, classes: 'awesome') }
  describe '#svg' do
    it 'returns a string' do
      expect(subject.svg).to be_an String
    end
    it 'returns raw svg' do
      expect(Capybara.string(subject.svg))
        .to have_css 'svg title', text: 'Search'
    end
  end
  describe '#options' do
    it 'applies options classes and default class' do
      expect(subject.options[:class]).to eq 'blacklight-icons awesome'
    end
  end
  describe '#path' do
    it 'prepends blacklight and sufixes .svg' do
      expect(subject.path).to eq 'blacklight/search.svg'
    end
  end
  describe 'file_source' do
    context 'file is not available' do
      subject { described_class.new(:yolo) }
      it { expect { subject.file_source }
        .to raise_error(Blacklight::Exceptions::IconNotFound) }
    end
    context 'file is available' do
      it 'returns the filesource' do
        expect(subject.file_source).to include '<svg'
      end
    end
  end
end
