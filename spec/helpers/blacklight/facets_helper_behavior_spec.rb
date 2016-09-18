# frozen_string_literal: true

RSpec.describe Blacklight::FacetsHelperBehavior do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before(:each) do
    allow(helper).to receive(:blacklight_config).and_return blacklight_config
  end

  describe "should_collapse_facet?" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'no_collapse', collapse: false
      end
    end

    it "is collapsed by default" do
      expect(helper.should_collapse_facet?(blacklight_config.facet_fields['basic_field'])).to be true
    end

    it "does not be collapsed if the configuration says so" do
      expect(helper.should_collapse_facet?(blacklight_config.facet_fields['no_collapse'])).to be false
    end

    it "does not be collapsed if it is in the params" do
      params[:f] = ActiveSupport::HashWithIndifferentAccess.new(basic_field: [1], no_collapse: [2])
      expect(helper.should_collapse_facet?(blacklight_config.facet_fields['basic_field'])).to be false
      expect(helper.should_collapse_facet?(blacklight_config.facet_fields['no_collapse'])).to be false
    end
  end

  describe "facet_by_field_name" do
    it "retrieves the facet from the response given a string" do
      facet_config = double(query: nil, field: 'b', key: 'a')
      facet_field = double()
      allow(helper).to receive(:facet_configuration_for_field).with('b').and_return(facet_config)
      @response = instance_double(Blacklight::Solr::Response, aggregations: { 'b' => facet_field })

      expect(helper.facet_by_field_name('b')).to eq facet_field
    end
  end

  describe "facet_field_in_params?" do
    it "checks if the facet field is selected in the user params" do
      allow(helper).to receive_messages(:params => { :f => { "some-field" => ["x"]}})
      expect(helper.facet_field_in_params?("some-field")).to be_truthy
      expect(helper.facet_field_in_params?("other-field")).to_not be true
    end
  end

  describe "facet_params" do
    it "extracts the facet parameters for a field" do
      allow(helper).to receive_messages(params: { f: { "some-field" => ["x"] }})
      expect(helper.facet_params("some-field")).to match_array ["x"]
    end

    it "uses the blacklight key to extract the right fields" do
      blacklight_config.add_facet_field "some-key", field: "some-field"
      allow(helper).to receive_messages(params: { f: { "some-key" => ["x"] }})
      expect(helper.facet_params("some-key")).to match_array ["x"]
      expect(helper.facet_params("some-field")).to match_array ["x"]
    end
  end

  describe "facet_field_in_params?" do
    it "checks if any value is selected for a given facet" do
      allow(helper).to receive_messages(facet_params: ["x"])
      expect(helper.facet_field_in_params?("some-facet")).to eq true
    end

    it "is false if no value for facet is selected" do
      allow(helper).to receive_messages(facet_params: nil)
      expect(helper.facet_field_in_params?("some-facet")).to eq false
    end
  end

  describe "facet_in_params?" do
    it "checks if a particular value is set in the facet params" do
      allow(helper).to receive_messages(facet_params: ["x"])
      expect(helper.facet_in_params?("some-facet", "x")).to eq true
      expect(helper.facet_in_params?("some-facet", "y")).to eq false
    end

    it "is false if no value for facet is selected" do
      allow(helper).to receive_messages(facet_params: nil)
      expect(helper.facet_in_params?("some-facet", "x")).to eq false
    end
  end

  describe "#facet_field_id" do
    it "is the parameterized version of the facet field" do
      expect(helper.facet_field_id double(key: 'some field')).to eq "facet-some-field"
    end
  end
end
