# frozen_string_literal: true

RSpec.describe "catalog/facet.json", :api do
  it "renders facet json" do
    assign :pagination, items: [{ value: 'Book' }]
    render template: "catalog/facet", formats: [:json]
    hash = JSON.parse(rendered)
    expect(hash).to eq('response' => { 'facets' => { 'items' => [{ 'value' => 'Book' }] } })
  end
end
