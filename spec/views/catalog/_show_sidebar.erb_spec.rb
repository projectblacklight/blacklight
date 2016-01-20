# frozen_string_literal: true
require 'spec_helper'

# spec for sidebar partial in catalog show view

describe "/catalog/_show_sidebar.html.erb" do

  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.index.title_field = 'title_display'
    end
  end

  before(:each) do
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:has_user_authentication_provider?).and_return(false)
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:document_actions).and_return([])
  end

  it "should show more-like-this titles in the sidebar" do
  	@document = SolrDocument.new :id => 1, :title_s => 'abc', :format => 'default'
  	allow(@document).to receive(:more_like_this).and_return([SolrDocument.new({ 'id' => '2', 'title_display' => 'Title of MLT Document' })])
    render
    expect(rendered).to include("More Like This")
    expect(rendered).to include("Title of MLT Document")
  end
end
