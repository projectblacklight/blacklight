# frozen_string_literal: true

describe 'catalog/opensearch.xml.builder' do
  it "renders an OpenSearch description document" do
    render
    doc = Nokogiri::XML.parse(rendered)
    doc.remove_namespaces!
    expect(doc.xpath('/OpenSearchDescription').length).to eq 1
  end
end
