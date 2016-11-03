RSpec.describe Blacklight::Configuration::FacetField do
  describe 'link_to_search' do
    subject { described_class.new(link_to_search: true) }

    it 'is deprecated' do
      expect(Deprecation).to receive(:warn)
      expect(subject.normalize!)
      expect(subject.link_to_facet).to eq true
    end
  end
end
