require 'spec_helper'

describe BlacklightConfigurationHelper do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:config_value) { double() }

  before :each do
    helper.stub(blacklight_config: blacklight_config)
  end

  describe "#index_fields" do
    it "should pass through the configuration" do
      blacklight_config.stub(index_fields: config_value)
      expect(helper.index_fields).to eq config_value
    end
  end

  describe "#sort_fields" do
    it "should convert the sort fields to select-ready values" do
      blacklight_config.stub(sort_fields: { 'a' => double(key: 'a', label: 'a'), 'b' => double(key: 'b', label: 'b'),  })
      expect(helper.sort_fields).to eq [['a', 'a'], ['b', 'b']]
    end
  end

  describe "#document_show_fields" do
    it "should pass through the configuration" do
      blacklight_config.stub(show_fields: config_value)
      expect(helper.document_show_fields).to eq config_value
    end
  end

  describe "#default_document_index_view_type" do
    it "should be the first configured index view" do
      blacklight_config.stub(view: { 'a' => true, 'b' => true})
      expect(helper.default_document_index_view_type).to eq 'a'
    end
  end

  describe "#has_alternative_views?" do
    subject { helper.has_alternative_views?}
    describe "with a single view defined" do
      it { should be_false }
    end

    describe "with multiple views defined" do
      before do
        blacklight_config.view.abc
        blacklight_config.view.xyz
      end

      it { should be_true }
    end
  end

  describe "#spell_check_max" do
    it "should pass through the configuration" do
      blacklight_config.stub(spell_max: config_value)
      expect(helper.spell_check_max).to eq config_value
    end
  end
end