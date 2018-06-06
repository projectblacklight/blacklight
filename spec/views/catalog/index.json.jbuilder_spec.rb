# frozen_string_literal: true

RSpec.describe "catalog/index.json", api: true do
  let(:response) { instance_double(Blacklight::Solr::Response, documents: docs, prev_page: nil, next_page: 2, total_pages: 3) }
  let(:docs) { [SolrDocument.new(id: '123', title_tsim: 'Book1'), SolrDocument.new(id: '456', title_tsim: 'Book2')] }
  let(:facets) { double("facets") }
  let(:config) { Blacklight::Configuration.new }
  let(:presenter) { Blacklight::JsonPresenter.new(response, facets, config) }

  let(:hash) do
    render template: "catalog/index.json", format: :json
    JSON.parse(rendered).with_indifferent_access
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(config)
    allow(view).to receive(:search_action_path).and_return('http://test.host/some/search/url')
    allow(view).to receive(:search_facet_path).and_return('http://test.host/some/facet/url')
    allow(presenter).to receive(:pagination_info).and_return({ current_page: 1, next_page: 2,
                                                               prev_page: nil })
    allow(presenter).to receive(:search_facets_as_json).and_return(
          [{ 'name' => "format", 'label' => "Format",
             'items' => [{ 'value' => 'Book', 'hits' => 30, 'label' => 'Book' }] }])
    assign :presenter, presenter
    assign :response, response
  end

  it "has pagination links" do
    expect(hash).to include(links: hash_including(
      self: 'http://test.host/',
      next: 'http://test.host/?page=2',
      last: 'http://test.host/?page=3'))
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
        attributes: { 'id' => '123', 'title_tsim' => 'Book1' },
        links: { self: 'http://test.host/catalog/123' }
      },
      {
        id: '456',
        attributes: { 'id' => '456', 'title_tsim' => 'Book2' },
        links: { self: 'http://test.host/catalog/456' }
      },
    ])
  end

  it "has facet information and links" do
    expect(hash).to include(:included)

    facets = hash[:included].select { |x| x['type'] == 'facet' }
    expect(facets).to be_present

    expect(facets.map { |x| x['id'] }).to include 'format'

    format = facets.find { |x| x['id'] == 'format' }

    expect(format['links']).to include self: 'http://test.host/some/facet/url'
    expect(format['attributes']).to include :items

    format_items = format['attributes']['items'].map { |x| x['attributes'] }

    expect(format_items).to match_array [{value: 'Book', hits: 30, label: 'Book'}]
  end
end
