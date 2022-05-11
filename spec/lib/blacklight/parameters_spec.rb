# frozen_string_literal: true

RSpec.describe Blacklight::Parameters do
  describe "sanitize_search_params" do
    subject { described_class.sanitize(params) }

    context "with nil values" do
      let(:params) { ActionController::Parameters.new a: nil, b: 1 }

      it "removes them" do
        expect(subject).not_to have_key(:a)
        expect(subject[:b]).to eq 1
      end
    end

    context "with blacklisted keys" do
      let(:params) { ActionController::Parameters.new action: true, controller: true, id: true, commit: true, utf8: true }

      it "removes them" do
        expect(subject).to be_empty
      end
    end
  end

  describe '.deep_merge_permitted_params' do
    it 'merges scalar values' do
      expect(described_class.deep_merge_permitted_params([:a], [:b])).to eq [:a, :b]
    end

    it 'appends complex values' do
      expect(described_class.deep_merge_permitted_params([:a], { b: [] })).to eq [:a, { b: [] }]
    end

    it 'merges lists of scalar values' do
      expect(described_class.deep_merge_permitted_params({ f: [:a, :b] }, { f: [:b, :c] })).to eq [{ f: [:a, :b, :c] }]
    end

    it 'merges complex value data structures' do
      expect(described_class.deep_merge_permitted_params([{ f: { field1: [] } }], { f: { field2: [] } })).to eq [{ f: { field1: [], field2: [] } }]
    end

    it 'takes the most permissive value' do
      expect(described_class.deep_merge_permitted_params([{ f: {} }], { f: { field2: [] } })).to eq [{ f: {} }]
      expect(described_class.deep_merge_permitted_params([{ f: {} }], { f: [:some_value] })).to eq [{ f: {} }]
    end
  end

  describe '#permit_search_params' do
    subject(:params) { described_class.new(query_params, search_state) }

    let(:query_params) { ActionController::Parameters.new(a: 1, b: 2, c: []) }
    let(:search_state) { Blacklight::SearchState.new(query_params, blacklight_config) }
    let(:blacklight_config) { Blacklight::Configuration.new }

    context 'with facebooks badly mangled query parameters' do
      let(:query_params) do
        ActionController::Parameters.new(
          f: { field: { '0': 'first', '1': 'second' } },
          f_inclusive: { field: { '0': 'first', '1': 'second' } }
        )
      end

      before do
        blacklight_config.add_facet_field 'field'
      end

      it 'normalizes the facets to the expected format' do
        expect(params.permit_search_params.to_h.with_indifferent_access).to include f: { field: %w[first second] }, f_inclusive: { field: %w[first second] }
      end
    end

    context 'with filter_search_state_fields set to false' do
      let(:blacklight_config) { Blacklight::Configuration.new(filter_search_state_fields: false) }

      it 'allows all params, but warns about the behavior' do
        allow(Deprecation).to receive(:warn)
        expect(params.permit_search_params.to_h.with_indifferent_access).to include(a: 1, b: 2, c: [])

        expect(Deprecation).to have_received(:warn).with(described_class, /including: a, b, and c/).at_least(:once)
      end
    end

    context 'with filter_search_state_fields set to true' do
      let(:blacklight_config) { Blacklight::Configuration.new(filter_search_state_fields: true) }

      it 'rejects unknown params' do
        expect(params.permit_search_params.to_h).to be_empty
      end

      context 'with some search parameters' do
        let(:query_params) { ActionController::Parameters.new(q: 'abc', page: 5, f: { facet_field: %w[a b], unknown_field: ['a'] }) }

        before do
          blacklight_config.add_facet_field 'facet_field'
        end

        it 'allows scalar params' do
          expect(params.permit_search_params.to_h.with_indifferent_access).to include(q: 'abc', page: 5)
        end

        it 'allows facet params' do
          expect(params.permit_search_params.to_h.with_indifferent_access).to include(f: { facet_field: %w[a b] })
        end

        it 'removes unknown facet fields parameters' do
          expect(params.permit_search_params.to_h.with_indifferent_access[:f]).not_to include(:unknown_field)
        end
      end
    end
  end
end
