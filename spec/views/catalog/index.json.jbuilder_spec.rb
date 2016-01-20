# frozen_string_literal: true
require 'spec_helper'
describe "catalog/index.json" do
  let(:response) { double("response") }
  let(:docs) { [{ id: '123', title_t: 'Book1' }, { id: '456', title_t: 'Book2' }] }
  let(:facets) { double("facets") }
  let(:config) { double("config") }
  let(:presenter) { Blacklight::JsonPresenter.new(response, docs, facets, config) }

  it "renders index json" do
    allow(presenter).to receive(:pagination_info).and_return({ current_page: 1, next_page: 2,
                                                               prev_page: nil })
    allow(presenter).to receive(:search_facets_as_json).and_return(
          [{ name: "format", label: "Format",
             items: [{ value: 'Book', hits: 30, label: 'Book' }] }])
    assign :presenter, presenter
    render template: "catalog/index.json", format: :json
    hash = JSON.parse(rendered)
    expect(hash).to eq('response' => { 'docs' => [{ 'id' => '123', 'title_t' => 'Book1' },
                                                  { 'id' => '456', 'title_t' => 'Book2' }],
                                       'facets' => [{ 'name' => "format", 'label' => "Format",
                                                      'items' => [
                                                        { 'value' => 'Book',
                                                          'hits' => 30,
                                                          'label' => 'Book' }] }],
                                       'pages' => { 'current_page' =>  1,
                                                    'next_page' => 2,
                                                    'prev_page' => nil } }
                      )
  end
end
