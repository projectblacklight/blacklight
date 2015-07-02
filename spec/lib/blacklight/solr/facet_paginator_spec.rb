require 'spec_helper'

describe Blacklight::Solr::FacetPaginator do
  let(:f1) { Blacklight::SolrResponse::Facets::FacetItem.new(hits: '792', value: 'Book') }
  describe "#as_json" do
    subject { described_class.new([f1], offset: 0, limit: nil).as_json }
    it "should be well structured" do
      expect(subject).to eq("items" => [{"hits"=>"792", "value"=>"Book"}], "limit" => nil,
       "offset" => 0, "sort" => "count")
    end
  end
end
