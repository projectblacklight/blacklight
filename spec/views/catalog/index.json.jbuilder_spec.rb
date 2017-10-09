# frozen_string_literal: true
RSpec.describe "catalog/index.json" do
  let(:response) { instance_double(Blacklight::Solr::Response, documents: docs, prev_page: nil, next_page: 2, total_pages: 3) }
  let(:docs) { [SolrDocument.new(id: '123', title_t: 'Book1'), SolrDocument.new(id: '456', title_t: 'Book2')] }
  let(:config) { Blacklight::Configuration.new }
  let(:presenter) { Blacklight::JsonPresenter.new(response, config) }

  let(:hash) do
    render template: "catalog/index.json", format: :json
    JSON.parse(rendered).with_indifferent_access
  end
  let(:facet_list_presenter) do
    instance_double(Blacklight::FacetListPresenter,
                    as_json:
                      [{ 'name' => "format", 'label' => "Format",
                         'items' => [
                            {
                              'attributes' => { 'value' => 'Book', 'hits' => 30, 'label' => 'Book' },
                              'links' => { 'self' => 'http://host.com/foo/bar' }
                            }
                          ]
                      }]
                   )
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(config)
    allow(view).to receive(:search_action_path).and_return('http://test.host/some/search/url')
    allow(view).to receive(:search_facet_path).and_return('http://test.host/some/facet/url')
    allow(presenter).to receive(:pagination_info).and_return({ current_page: 1, next_page: 2,
                                                               prev_page: nil })
    allow(presenter).to receive(:facets).and_return(facet_list_presenter)

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
        attributes: { 'id' => '123', 'title_t' => 'Book1' },
        links: { self: 'http://test.host/catalog/123' }
      },
      {
        id: '456',
        attributes: { 'id' => '456', 'title_t' => 'Book2' },
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
