# frozen_string_literal: true
describe "catalog/facet.json" do
  it "renders facet json" do
    assign :pagination, { items: [{ value: 'Book' }] }
    render template: "catalog/facet.json", format: :json
    hash = JSON.parse(rendered)
    expect(hash).to eq('response' => { 'facets' => { 'items' => [{ 'value' => 'Book' }] } })
  end
end
