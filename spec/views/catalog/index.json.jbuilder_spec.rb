# frozen_string_literal: true

RSpec.describe "catalog/index.json", api: true do
  let(:response) { instance_double(Blacklight::Solr::Response, documents: docs, prev_page: nil, next_page: 2, total_pages: 3) }
  let(:docs) do
    [
      SolrDocument.new(id: '123', title_tsim: 'Book1', author_tsim: 'Julie', format: 'Book'),
      SolrDocument.new(id: '456', title_tsim: 'Article1', author_tsim: 'Rosie', format: 'Article')
    ]
  end
  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_index_field 'title', label: 'Title', field: 'title_tsim'
    end
  end
  let(:presenter) { Blacklight::JsonPresenter.new(response, config) }

  let(:hash) do
    render template: "catalog/index.json", format: :json
    JSON.parse(rendered).with_indifferent_access
  end

  let(:book_facet_item) do
    Blacklight::Solr::Response::Facets::FacetItem.new('value' => 'Book', 'hits' => 30, 'label' => 'Book')
  end

  let(:format_facet) do
    Blacklight::Solr::Response::Facets::FacetField.new('format',
                                                       [book_facet_item],
                                                       'label' => 'Format')
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(config)
    allow(view).to receive(:search_action_path).and_return('http://test.host/some/search/url')
    allow(view).to receive(:search_facet_path).and_return('http://test.host/some/facet/url')
    allow(presenter).to receive(:pagination_info).and_return(current_page: 1,
                                                             next_page: 2,
                                                             prev_page: nil)
    allow(presenter).to receive(:search_facets).and_return([format_facet])
    assign :presenter, presenter
    assign :response, response
  end

  it "has pagination links" do
    expect(hash).to include(links: hash_including(
      self: 'http://test.host/',
      next: 'http://test.host/?page=2',
      last: 'http://test.host/?page=3'
    ))
  end

  it "has pagination information" do
    expect(hash).to include(meta: hash_including(pages:
      {
        'current_page' =>  1,
        'next_page' => 2,
        'prev_page' => nil
      }))
  end

  it "includes documents, links, and their attributes" do
    expect(hash).to include(data: [
                              {
                                id: '123',
                                type: 'Book',
                                attributes: {
                                  'title': {
                                    id: 'http://test.host/catalog/123#title',
                                    type: 'document_value',
                                    attributes: {
                                      value: 'Book1',
                                      label: 'Title'
                                    }
                                  }
                                },
                                links: { self: 'http://test.host/catalog/123' }
                              },
                              {
                                id: '456',
                                type: 'Article',
                                attributes: {
                                  'title': {
                                    id: 'http://test.host/catalog/456#title',
                                    type: 'document_value',
                                    attributes: {
                                      value: 'Article1',
                                      label: 'Title'
                                    }
                                  }
                                },
                                links: { self: 'http://test.host/catalog/456' }
                              }
                            ])
  end

  describe 'facets' do
    let(:facets) { hash[:included].select { |x| x['type'] == 'facet' } }
    let(:format) { facets.find { |x| x['id'] == 'format' } }
    let(:format_items) { format['attributes']['items'] }
    let(:format_item_attributes) { format_items.map { |x| x['attributes'] } }

    context 'when no facets have been selected' do
      it 'has facet information and links' do
        expect(facets).to be_present
        expect(facets.map { |x| x['id'] }).to include 'format'
        expect(format['links']).to include self: 'http://test.host/some/facet/url'
        expect(format['attributes']['label']).to eq 'Format'
        expect(format_item_attributes).to match_array [{ value: 'Book', hits: 30, label: 'Book' }]
      end
    end

    context 'when facets have been selected' do
      before do
        params[:f] = { format: ['Book'] }
      end

      it 'has a link to remove the selected value' do
        expect(format_items.first['links']).to eq('remove' => 'http://test.host/some/search/url')
      end
    end
  end
end
