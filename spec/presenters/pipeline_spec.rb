# frozen_string_literal: true

describe Blacklight::Rendering::Pipeline do
  include Capybara::RSpecMatchers
  let(:document) { instance_double(SolrDocument) }
  let(:context) { double }
  let(:options) { double }
  let(:presenter) { described_class.new(values, field_config, document, context, options) }

  describe "render" do
    subject { presenter.render }
    let(:values) { ['a', 'b'] }
    let(:field_config) { Blacklight::Configuration::NullField.new } 
    it { is_expected.to eq "a and b" }

    context "when separator_options are in the config" do
      let(:values) { ['c', 'd'] }
      let(:field_config) { Blacklight::Configuration::NullField.new(separator: nil, itemprop: nil, separator_options: { two_words_connector: '; '}) } 
      it { is_expected.to eq "c; d" }
    end

    context "when itemprop is in the config" do
      let(:values) { ['a'] }
      let(:field_config) { Blacklight::Configuration::NullField.new(separator: nil, itemprop: 'some-prop', separator_options: nil) } 
      it { is_expected.to have_selector("span[@itemprop='some-prop']", :text => "a") }
    end
  end

  describe "#operations" do
    subject { described_class.operations }
    it { is_expected.to eq [Blacklight::Rendering::HelperMethod,
                            Blacklight::Rendering::LinkToFacet,
                            Blacklight::Rendering::Microdata,
                            Blacklight::Rendering::Join] }
  end
end
