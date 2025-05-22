# frozen_string_literal: true

RSpec.describe Blacklight::Solr::DefaultFilterQueryBuilder do
  subject { described_class.new(blacklight_config: blacklight_config) }

  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }

  describe "#facet_value_to_fq_string" do
    it "uses the configured field name" do
      blacklight_config.add_facet_field :facet_key, field: "facet_name"
      expect(subject.send(:facet_value_to_fq_string, "facet_key", "my value")).to eq "{!term f=facet_name}my value"
    end

    it "uses the raw handler for strings" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "my value")).to eq "{!term f=facet_name}my value"
    end

    it "passes booleans through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", true)).to eq '{!term f=facet_name}true'
    end

    it "passes boolean-like strings through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "true")).to eq '{!term f=facet_name}true'
    end

    it "passes integers through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", 1)).to eq '{!term f=facet_name}1'
    end

    it "passes integer-like strings through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "1")).to eq '{!term f=facet_name}1'
      expect(subject.send(:facet_value_to_fq_string, "facet_name", -1)).to eq '{!term f=facet_name}-1'
    end

    it "passes floats through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", 1.11)).to eq '{!term f=facet_name}1.11'
    end

    it "passes floats in strings through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "1.11")).to eq '{!term f=facet_name}1.11'
    end

    context 'date handling' do
      before { allow(blacklight_config.facet_fields).to receive(:[]).with('facet_name').and_return(double(date: true, query: nil, tag: nil, field: 'facet_name')) }

      it "passes date-type fields through" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "2012-01-01")).to eq '{!term f=facet_name}2012-01-01'
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "2003-04-09T00:00:00Z")).to eq '{!term f=facet_name}2003-04-09T00:00:00Z'
      end

      it "formats Date objects correctly" do
        allow(blacklight_config.facet_fields).to receive(:[]).with('facet_name').and_return(double(date: nil, query: nil, tag: nil, field: 'facet_name'))
        d = DateTime.parse("2003-04-09T00:00:00")
        expect(subject.send(:facet_value_to_fq_string, "facet_name", d)).to eq '{!term f=facet_name}2003-04-09T00:00:00Z'
      end
    end

    it "handles range requests" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", 1..5)).to eq "facet_name:[1 TO 5]"
      expect(subject.send(:facet_value_to_fq_string, "facet_name", 1..nil)).to eq "facet_name:[1 TO *]"
      expect(subject.send(:facet_value_to_fq_string, "facet_name", nil..5)).to eq "facet_name:[* TO 5]"
      expect(subject.send(:facet_value_to_fq_string, "facet_name", nil..nil)).to eq "facet_name:[* TO *]"
    end

    it "adds tag local parameters" do
      allow(blacklight_config.facet_fields).to receive(:[]).with('facet_name').and_return(double(query: nil, tag: 'asdf', date: nil, field: 'facet_name'))

      expect(subject.send(:facet_value_to_fq_string, "facet_name", true)).to eq "{!term f=facet_name tag=asdf}true"
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "my value")).to eq "{!term f=facet_name tag=asdf}my value"
    end
  end
end
