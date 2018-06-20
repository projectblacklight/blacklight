# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# spec for sidebar partial in catalog show view

describe "/catalog/_show_sidebar.html.erb" do
  
  include BlacklightHelper
  include CatalogHelper


  before(:each) do

    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    allow(view).to receive(:has_user_authentication_provider?).and_return(false)
    allow(view).to receive(:current_search_session).and_return nil
  end

  it "should show more-like-this titles in the sidebar" do
  	@document = SolrDocument.new :id => 1, :title_s => 'abc', :format => 'default'
  	allow(@document).to receive(:more_like_this).and_return([SolrDocument.new({ 'id' => '2', 'title_display' => 'Title of MLT Document' })])
    render
    expect(rendered).to include_text("More Like This")
    expect(rendered).to include_text("Title of MLT Document")
  end
end
