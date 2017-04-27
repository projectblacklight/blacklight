# frozen_string_literal: true
RSpec.describe "catalog/index.json" do
  let(:response) { instance_double(Blacklight::Solr::Response, documents: docs, prev_page: nil, next_page: 2, total_pages: 3) }
  let(:docs) { [SolrDocument.new(id: '123', title_t: 'Book1'), SolrDocument.new(id: '456', title_t: 'Book2')] }
  let(:facets) { double("facets") }
  let(:config) { Blacklight::Configuration.new }
  let(:presenter) { Blacklight::JsonPresenter.new(response, facets, config) }

  it "renders index json" do
    allow(view).to receive(:blacklight_config).and_return(config)
    allow(presenter).to receive(:pagination_info).and_return({ current_page: 1, next_page: 2,
                                                               prev_page: nil })
    allow(presenter).to receive(:search_facets_as_json).and_return(
          [{ name: "format", label: "Format",
             items: [{ value: 'Book', hits: 30, label: 'Book' }] }])
    assign :presenter, presenter
    assign :response, response
    render template: "catalog/index.json", format: :json
    hash = JSON.parse(rendered).with_indifferent_access
    expect(hash).to include(links: hash_including(self: 'http://test.host/', next: 'http://test.host/?page=2', last: 'http://test.host/?page=3'))
    expect(hash).to include(response: hash_including(facets: [
      { 
        'name' => "format", 'label' => "Format",
        'items' => [
          { 'value' => 'Book',
            'hits' => 30,
            'label' => 'Book' }] 
      }]))
    expect(hash).to include(response: hash_including(pages: 
      { 
        'current_page' =>  1,
        'next_page' => 2,
        'prev_page' => nil 
      }))
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
end
