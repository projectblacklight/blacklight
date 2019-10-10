# frozen_string_literal: true

RSpec.describe Blacklight::Rendering::Pipeline do
  include Capybara::RSpecMatchers
  let(:document) { instance_double(SolrDocument) }
  let(:context) { double }
  let(:options) { double('options') }

  describe '.render' do
    subject { described_class.render(values, field_config, document, context, options) }

    let(:values) { %w[a b] }
    let(:field_config) { Blacklight::Configuration::NullField.new }

    it { is_expected.to eq "a and b" }

    context "when separator_options are in the config" do
      let(:values) { %w[c d] }
      let(:field_config) { Blacklight::Configuration::NullField.new(itemprop: nil, separator_options: { two_words_connector: '; ' }) }

      it { is_expected.to eq "c; d" }
    end

    context "when itemprop is in the config" do
      let(:values) { ['a'] }
      let(:field_config) { Blacklight::Configuration::NullField.new(itemprop: 'some-prop', separator_options: nil) }

      it { is_expected.to have_selector("span[@itemprop='some-prop']", text: "a") }
    end

    it 'sets the operations on the instance as equal to the class variable' do
      allow(described_class).to receive(:new)
        .and_return(instance_double(described_class, render: true))
      subject
      expect(described_class).to have_received(:new)
        .with(values, field_config, document, context, described_class.operations, options)
    end
  end

  describe '.operations' do
    subject { described_class.operations }

    it {
      expect(subject).to eq [Blacklight::Rendering::HelperMethod,
                             Blacklight::Rendering::LinkToFacet,
                             Blacklight::Rendering::Microdata,
                             Blacklight::Rendering::Join]
    }
  end

  describe '#operations' do
    subject(:operations) { presenter.operations }

    let(:presenter) { described_class.new(values, field_config, document, context, steps, options) }
    let(:steps) { [Blacklight::Rendering::HelperMethod] }
    let(:values) { ['a'] }
    let(:field_config) { Blacklight::Configuration::NullField.new }

    it 'sets the operations to the value passed to the initializer' do
      expect(operations).to eq steps
    end
  end
end
