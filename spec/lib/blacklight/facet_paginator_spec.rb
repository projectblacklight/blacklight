require 'spec_helper'

describe Blacklight::FacetPaginator do

  let(:f1) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '792', value: 'Book') }
  let(:f2) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '65', value: 'Musical Score') }
  let(:f3) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '58', value: 'Serial') }
  let(:f4) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '48', value: 'Musical Recording') }
  let(:f5) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '37', value: 'Microform') }
  let(:f6) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '27', value: 'Thesis') }
  let(:f7) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '0') }
  let(:seven_facet_values) { [f1, f2, f3, f4, f5, f6, f7] }
  let(:six_facet_values) { [f1, f2, f3, f4, f5, f6] }
  let(:limit) { 6 }

  context 'on the first page of two pages' do
    subject { described_class.new(seven_facet_values, limit: limit) }
    it { should be_first_page }
    it { should_not be_last_page }
    its(:current_page) { should eq 1 }
    its(:prev_page) { should be_nil }
    its(:next_page) { should eq 2 }
    it 'should limit items to limit, if limit is smaller than items.length' do
      expect(subject.items.size).to eq 6
    end
  end

  context 'on the last page of two pages' do
    subject { described_class.new([f7], offset: 6, limit: limit) }
    it { should_not be_first_page }
    it { should be_last_page }
    its(:current_page) { should eq 2 }
    its(:prev_page) { should eq 1 }
    its(:next_page) { should be_nil }
    it 'should return all items when limit is greater than items.length' do
      expect(subject.items.size).to eq 1
    end
  end

  context 'on the second page of three pages' do
    subject { described_class.new(seven_facet_values, offset: 6, limit: limit) }
    it { should_not be_first_page }
    it { should_not be_last_page }
    its(:current_page) { should eq 2 }
    its(:prev_page) { should eq 1 }
    its(:next_page) { should eq 3 }
    it 'should limit items to limit, if limit is smaller than items.length' do
      expect(subject.items.size).to eq 6
    end
  end

  context 'on the first page of one page' do
    subject { described_class.new(six_facet_values, offset: 0, limit: limit) }
    it { should be_first_page }
    it { should be_last_page }
  end

  describe "params_for_resort_url" do
    let(:sort_key) { described_class.request_keys[:sort] }
    let(:page_key) { described_class.request_keys[:page] }
    subject { described_class.new([], offset: 100, limit: limit, sort: 'index') }

    it 'should know a manually set sort, and produce proper sort url' do
        expect(subject.sort).to eq 'index'
        
        click_params = subject.params_for_resort_url('count', {})

        expect(click_params[ sort_key ]).to eq 'count'
        expect(click_params[ page_key ]).to be_nil
    end

    context 'when sorting by "count"' do
      subject { described_class.new([]) }

      it 'includes the prefix filter for "index" sorting' do
        expect(subject.params_for_resort_url('index', :'facet.prefix' => 'A')).to include :'facet.prefix' => 'A'
      end

      it 'removes the prefix filter' do
        expect(subject.params_for_resort_url('count', :'facet.prefix' => 'A')).not_to include :'facet.prefix' => 'A'
      end
    end
  end

  context "for a nil :limit" do
    subject { described_class.new(seven_facet_values, offset: 0, limit: nil) }
    it "should return all the items" do
      expect(subject.items).to eq seven_facet_values
    end
    it { should be_last_page }
  end

  describe "#as_json" do
    subject { described_class.new([f1], offset: 0, limit: nil).as_json }
    it "should be well structured" do
      expect(subject).to eq("items" => [{"hits"=>"792", "value"=>"Book"}], "limit" => nil,
       "offset" => 0, "sort" => nil)
    end
  end

  describe "#total_pages" do
    # this method is just for API compatability with kaminari 0.16.1
    subject { described_class.new([f1], offset: 0, limit: nil).total_pages }
    it { should eq -1 }
  end
end
