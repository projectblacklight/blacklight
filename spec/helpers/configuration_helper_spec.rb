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

  describe "#index_field_label" do
    let(:document) { double }
    it "should look up the label to display for the given document and field" do
      helper.stub(:index_fields).and_return({ "my_field" => double(label: "some label") })
      helper.should_receive(:solr_field_label).with("some label", :"blacklight.search.fields.index.my_field", :"blacklight.search.fields.my_field")
      helper.index_field_label document, "my_field"
    end
  end

  describe "#document_show_field_label" do
    let(:document) { double }
    it "should look up the label to display for the given document and field" do
      helper.stub(:document_show_fields).and_return({ "my_field" => double(label: "some label") })
      helper.should_receive(:solr_field_label).with("some label", :"blacklight.search.fields.show.my_field", :"blacklight.search.fields.my_field")
      helper.document_show_field_label document, "my_field"
    end
  end

  describe "#facet_field_label" do
    let(:document) { double }
    it "should look up the label to display for the given document and field" do
      blacklight_config.stub(:facet_fields).and_return({ "my_field" => double(label: "some label") })
      helper.should_receive(:solr_field_label).with("some label", :"blacklight.search.fields.facet.my_field", :"blacklight.search.fields.my_field")
      helper.facet_field_label "my_field"
    end
  end

  describe "#solr_field_label" do
    it "should look up the label as an i18n string" do
      helper.should_receive(:t).with(:some_key).and_return "my label"
      label = helper.solr_field_label :some_key

      expect(label).to eq "my label"
    end

    it "should pass the provided i18n keys to I18n.t" do
      helper.should_receive(:t).with(:key_a, default: [:key_b, "default text"])

      label = helper.solr_field_label "default text", :key_a, :key_b
    end
  end
  
  describe "#default_per_page" do
    it "should be the configured default per page" do
      helper.stub(blacklight_config: double(default_per_page: 42))
      expect(helper.default_per_page).to eq 42
    end
    
    it "should be the first per-page value if a default isn't set" do
      helper.stub(blacklight_config: double(default_per_page: nil, per_page: [11, 22]))
      expect(helper.default_per_page).to eq 11
    end
  end
  
  describe "#per_page_options_for_select" do
    it "should be the per-page values formatted as options_for_select" do
      helper.stub(blacklight_config: double(per_page: [11, 22, 33]))
      expect(helper.per_page_options_for_select).to include ["11<span class=\"sr-only\"> per page</span>", 11]
      expect(helper.per_page_options_for_select).to include ["22<span class=\"sr-only\"> per page</span>", 22]
      expect(helper.per_page_options_for_select).to include ["33<span class=\"sr-only\"> per page</span>", 33]
    end
  end
end
