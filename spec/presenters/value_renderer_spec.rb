# frozen_string_literal: true
require 'spec_helper'

describe Blacklight::ValueRenderer do
  include Capybara::RSpecMatchers
  let(:presenter) { Blacklight::ValueRenderer.new(values, field_config) }

  describe "render" do
    subject { presenter.render }
    let(:values) { ['a', 'b'] }
    let(:field_config) { nil } 
    it { is_expected.to eq "a and b" }

    context "when separator_options are in the config" do
      let(:values) { ['c', 'd'] }
      let(:field_config) { double(separator: nil, itemprop: nil, separator_options: { two_words_connector: '; '}) } 
      it { is_expected.to eq "c; d" }
    end

    context "when itemprop is in the config" do
      let(:values) { ['a'] }
      let(:field_config) { double(separator: nil, itemprop: 'some-prop', separator_options: nil) } 
      it { is_expected.to have_selector("span[@itemprop='some-prop']", :text => "a") }
    end
  end
end
