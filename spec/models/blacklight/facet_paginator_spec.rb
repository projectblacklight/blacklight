# frozen_string_literal: true

RSpec.describe Blacklight::FacetPaginator, :api do
  let(:book) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '792', value: 'Book') }
  let(:musical_score) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '65', value: 'Musical Score') }
  let(:serial) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '58', value: 'Serial') }
  let(:musical_recording) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '48', value: 'Musical Recording') }
  let(:microform) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '37', value: 'Microform') }
  let(:thesis) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '27', value: 'Thesis') }
  let(:blank) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '0') }
  let(:seven_facet_values) { [book, musical_score, serial, musical_recording, microform, thesis, blank] }
  let(:six_facet_values) { [book, musical_score, serial, musical_recording, microform, thesis] }
  let(:limit) { 6 }

  context 'on the first page of two pages' do
    subject(:paginator) { described_class.new(seven_facet_values, limit: limit) }

    it { is_expected.to be_first_page }
    it { is_expected.not_to be_last_page }

    describe '#current_page' do
      subject { paginator.current_page }

      it { is_expected.to eq 1 }
    end

    describe '#prev_page' do
      subject { paginator.prev_page }

      it { is_expected.to be_nil }
    end

    describe '#next_page' do
      subject { paginator.next_page }

      it { is_expected.to eq 2 }
    end

    it 'limits items to limit, if limit is smaller than items.length' do
      expect(paginator.items.size).to eq 6
    end
  end

  context 'on the last page of two pages' do
    subject(:paginator) { described_class.new([blank], offset: 6, limit: limit) }

    it { is_expected.not_to be_first_page }
    it { is_expected.to be_last_page }

    describe '#current_page' do
      subject { paginator.current_page }

      it { is_expected.to eq 2 }
    end

    describe '#prev_page' do
      subject { paginator.prev_page }

      it { is_expected.to eq 1 }
    end

    describe '#next_page' do
      subject { paginator.next_page }

      it { is_expected.to be_nil }
    end

    it 'returns all items when limit is greater than items.length' do
      expect(paginator.items.size).to eq 1
    end
  end

  context 'on the second page of three pages' do
    subject(:paginator) { described_class.new(seven_facet_values, offset: 6, limit: limit) }

    it { is_expected.not_to be_first_page }
    it { is_expected.not_to be_last_page }

    describe '#current_page' do
      subject { paginator.current_page }

      it { is_expected.to eq 2 }
    end

    describe '#prev_page' do
      subject { paginator.prev_page }

      it { is_expected.to eq 1 }
    end

    describe '#next_page' do
      subject { paginator.next_page }

      it { is_expected.to eq 3 }
    end

    it 'limits items to limit, if limit is smaller than items.length' do
      expect(paginator.items.size).to eq 6
    end
  end

  context 'on the first page of one page' do
    subject { described_class.new(six_facet_values, offset: 0, limit: limit) }

    it { is_expected.to be_first_page }
    it { is_expected.to be_last_page }
  end

  describe "params_for_resort_url" do
    subject { described_class.new([], offset: 100, limit: limit, sort: 'index') }

    let(:sort_key) { described_class.request_keys[:sort] }
    let(:page_key) { described_class.request_keys[:page] }

    it 'knows a manually set sort, and produce proper sort url' do
      expect(subject.sort).to eq 'index'

      click_params = subject.params_for_resort_url('count', {}.with_indifferent_access)

      expect(click_params[sort_key]).to eq 'count'
      expect(click_params[page_key]).to be_nil
    end

    context 'when sorting by "count"' do
      subject { described_class.new([]) }

      let(:params) { ActiveSupport::HashWithIndifferentAccess.new 'facet.prefix': 'A' }

      it 'includes the prefix filter for "index" sorting' do
        expect(subject.params_for_resort_url('index', params)).to include 'facet.prefix': 'A'
      end

      it 'removes the prefix filter' do
        expect(subject.params_for_resort_url('count', params)).not_to include 'facet.prefix': 'A'
      end
    end
  end

  context "for a nil :limit" do
    let(:paginator) { described_class.new(seven_facet_values, offset: 0, limit: nil) }

    describe "#items" do
      subject { paginator.items }

      it { is_expected.to eq seven_facet_values }
    end

    describe "#last_page?" do
      subject { paginator.last_page? }

      it { is_expected.to be true }
    end

    describe "#current_page" do
      subject { paginator.current_page }

      it { is_expected.to eq 1 }
    end
  end

  describe "#as_json" do
    subject { described_class.new([book], offset: 0, limit: nil).as_json }

    it "is well structured" do
      expect(subject).to eq("items" => [{ "hits" => "792", "value" => "Book" }], "limit" => nil,
                            "offset" => 0, "sort" => nil)
    end
  end

  describe "#total_pages" do
    # this method is just for API compatability with kaminari 0.16.1
    subject { described_class.new([book], offset: 0, limit: nil).total_pages }

    it { is_expected.to eq -1 }
  end
end
