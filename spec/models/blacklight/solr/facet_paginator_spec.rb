# frozen_string_literal: true

RSpec.describe Blacklight::Solr::FacetPaginator, :api do
  let(:f1) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '792', value: 'Book') }

  describe "#as_json" do
    subject { described_class.new([f1], offset: 0, limit: nil).as_json }

    it "is well structured" do
      expect(subject).to eq("items" => [{ "hits" => "792", "value" => "Book" }], "limit" => nil,
                            "offset" => 0, "sort" => "index")
    end
  end

  describe '#sort' do
    it 'defaults to "count" if a limit is provided' do
      expect(described_class.new([], limit: 10).sort).to eq 'count'
    end

    it 'defaults to "index" if no limit is given' do
      expect(described_class.new([]).sort).to eq 'index'
    end

    it 'handles json facet api-style parameter sorts' do
      expect(described_class.new([], sort: { count: :desc }).sort).to eq 'count'
    end
  end
end
