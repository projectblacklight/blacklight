require 'spec_helper'

RSpec.describe Blacklight::Configuration::FacetField do
  describe 'link_to_search' do
    subject { described_class.new(link_to_search: true) }

    it 'is deprecated' do
      expect(Deprecation).to receive(:warn)
      expect(subject.normalize!)
      expect(subject.link_to_facet).to eq true
    end
  end

  describe "#facet_field_label" do
    let(:instance) { described_class.new(key: "my_field", label: "some label") }
    before do
      allow(instance).to receive(:field_label).with(:"blacklight.search.fields.facet.my_field", :"blacklight.search.fields.my_field", "some label", "My field")
    end

    it "looks up the label to display for the given document and field" do
      instance.facet_field_label
    end
  end
end
