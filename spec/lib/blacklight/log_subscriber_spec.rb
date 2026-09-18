# frozen_string_literal: true

RSpec.describe Blacklight::LogSubscriber do
  subject(:subscriber) { described_class.new }

  let(:output) { StringIO.new }
  let(:embedding) { "[#{Array.new(768) { 0.0123456789 }.join(', ')}]" }
  let(:params) do
    { q: 'sunflowers', json: { query: { knn: { f: 'vector', topK: 10, query: embedding } } } }
  end
  let(:event) do
    ActiveSupport::Notifications::Event.new('solr_request.blacklight', Time.zone.now, Time.zone.now, 'id',
                                            method: :post, path: 'select', params: params)
  end

  around do |example|
    original_logger = Blacklight.logger
    Blacklight.logger = ActiveSupport::Logger.new(output)
    example.run
    Blacklight.logger = original_logger
  end

  describe '#solr_request' do
    it 'logs the request' do
      subscriber.solr_request(event)

      # Hash#inspect formats keys differently across supported Rubies, so match on the values.
      expect(output.string).to include('Solr fetch', 'post select', 'sunflowers', 'vector')
    end

    it 'logs the parameters through the default filter, which omits the query vector' do
      subscriber.solr_request(event)

      expect(output.string).to include("OMITTED (#{embedding.length} characters)")
      expect(output.string).not_to include('0.0123456789')
    end

    context 'with a configured params_filter' do
      around do |example|
        original_filter = described_class.params_filter
        described_class.params_filter = ->(params) { params.except(:json) }
        example.run
        described_class.params_filter = original_filter
      end

      it 'logs what the filter returns' do
        subscriber.solr_request(event)

        expect(output.string).to include('sunflowers')
        expect(output.string).not_to include('vector')
      end
    end
  end
end
