# frozen_string_literal: true

RSpec.describe Blacklight::FieldRetriever, :api do
  let(:service) { described_class.new(document, blacklight_field_config) }

  let(:blacklight_field_config) { Blacklight::Configuration::Field.new(field: 'author_field', highlight: true) }
  let(:document) { SolrDocument.new({ 'id' => 'doc1', 'title_field' => 'doc1 title', 'author_field' => 'author_someone' }, 'highlighting' => { 'doc1' => { 'title_tsimext' => ['doc <em>1</em>'] } }) }
  let(:view_context) { {} }

  context "highlighting" do
    describe '#fetch' do
      it "retrieves an author even if it's not highlighted" do
        expect(service.fetch).to eq(['author_someone'])
      end
    end
  end
end
