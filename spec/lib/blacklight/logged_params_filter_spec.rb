# frozen_string_literal: true

RSpec.describe Blacklight::LoggedParamsFilter do
  subject(:filter) { described_class.new }

  let(:embedding) { "[#{Array.new(768) { 0.0123456789 }.join(', ')}]" }
  let(:params) do
    { q: 'sunflowers', rows: 10, json: { query: { knn: { f: 'vector', topK: 10, query: embedding } } } }
  end

  describe '#call' do
    it 'replaces values longer than max_value_length wherever they are nested' do
      expect(filter.call(params)).to eq(
        q: 'sunflowers',
        rows: 10,
        json: { query: { knn: { f: 'vector', topK: 10, query: "OMITTED (#{embedding.length} characters)" } } }
      )
    end

    it 'replaces over-long values within arrays' do
      expect(filter.call(fq: ['format:Book', embedding])).to eq(fq: ['format:Book', "OMITTED (#{embedding.length} characters)"])
    end

    it 'does not modify the parameters it was given' do
      filter.call(params)

      expect(params.dig(:json, :query, :knn, :query)).to eq embedding
    end

    context 'with a custom max_value_length' do
      subject(:filter) { described_class.new(max_value_length: 5) }

      it 'replaces anything longer' do
        expect(filter.call(q: 'sunflowers')).to eq(q: 'OMITTED (10 characters)')
      end

      it 'keeps values of exactly that length' do
        expect(filter.call(q: 'roses')).to eq(q: 'roses')
      end
    end

    context 'with a nil max_value_length' do
      subject(:filter) { described_class.new(max_value_length: nil) }

      it 'returns every value in full' do
        expect(filter.call(params)).to eq params
      end
    end
  end
end
