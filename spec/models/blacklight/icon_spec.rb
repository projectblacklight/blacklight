# frozen_string_literal: true

RSpec.describe Blacklight::Icon do
  subject { described_class.new(:search, classes: 'awesome', aria_hidden: true) }

  describe '#svg' do
    it 'returns a string' do
      expect(subject.svg).to be_an String
    end

    it 'returns raw svg' do
      expect(Capybara.string(subject.svg))
        .to have_css 'svg[width="24"]'
    end

    it 'adds role="img"' do
      expect(Capybara.string(subject.svg))
        .to have_css 'svg[role="img"]'
    end

    it 'adds title' do
      expect(Capybara.string(subject.svg))
        .to have_css 'title', text: 'Search'
    end

    context 'when label is false' do
      subject { described_class.new(:search, classes: 'awesome', aria_hidden: true, label: false) }

      it 'does not add title' do
        expect(Capybara.string(subject.svg))
          .not_to have_css 'title', text: 'Search'
      end
    end

    context ' with a label context' do
      subject { described_class.new(:search, classes: 'awesome', aria_hidden: true, additional_options: { label_context: 'foo' }) }

      it 'adds title' do
        expect(Capybara.string(subject.svg))
          .to have_css 'title', text: 'Search'
      end
    end
  end

  describe '#options' do
    it 'applies options classes and default class' do
      expect(subject.options[:class]).to eq 'blacklight-icons blacklight-icon-search awesome'
    end

    it 'applies options aria-hidden=true' do
      expect(subject.options[:'aria-hidden']).to be true
    end

    context 'no options provided' do
      subject { described_class.new(:view) }

      it 'applies default class with no options' do
        expect(subject.options[:class]).to eq 'blacklight-icons blacklight-icon-view'
      end

      it 'has no aria-hidden attribute with no options' do
        expect(subject.options[:'aria-hidden']).to be nil
      end
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

      it {
        expect { subject.file_source }
          .to raise_error(Blacklight::Exceptions::IconNotFound)
      }
    end

    context 'file is available' do
      it 'returns the filesource' do
        expect(subject.file_source).to include '<svg'
      end
    end
  end
end
