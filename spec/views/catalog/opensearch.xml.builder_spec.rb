# frozen_string_literal: true
require 'spec_helper'

describe 'catalog/opensearch.xml.builder' do
  it "should render an OpenSearch description document" do
    render
    doc = Nokogiri::XML.parse(rendered)
    doc.remove_namespaces!
    expect(doc.xpath('/OpenSearchDescription').length).to eq 1
  end
end
