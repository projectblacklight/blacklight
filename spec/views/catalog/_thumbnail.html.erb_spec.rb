# frozen_string_literal: true

describe "catalog/_thumbnail" do

  let :document_without_thumbnail_field do
    SolrDocument.new :id => 'xyz', :format => 'a'
  end

  let :document_with_thumbnail_field do
    SolrDocument.new :id => 'xyz', :format => 'a', :thumbnail_url => 'http://localhost/logo.png'
  end

  let :blacklight_config do
    Blacklight::Configuration.new do |config|
      config.index.thumbnail_field = :thumbnail_url
    end
  end

  before do
    allow(controller).to receive(:action_name).and_return('index')
    assign :response, instance_double(Blacklight::Solr::Response, start: 0)
    allow(view).to receive(:render_grouped_response?).and_return false
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
  end

  it "renders the thumbnail if the document has one" do
    render :partial => "catalog/thumbnail", :locals => {:document => document_with_thumbnail_field, :document_counter => 1}
    expect(rendered).to match /document-thumbnail/
    expect(rendered).to match /src="http:\/\/localhost\/logo.png"/
  end

  it "does not render a thumbnail if the document does not have one" do
    render :partial => "catalog/thumbnail", :locals => {:document => document_without_thumbnail_field, :document_counter => 1}
    expect(rendered).to eq ""
  end
end
