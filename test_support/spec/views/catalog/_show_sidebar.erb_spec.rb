# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# spec for sidebar partial in catalog show view

describe "/catalog/_show_sidebar.html.erb" do
  
  include BlacklightHelper
  include CatalogHelper


  before(:each) do

    view.stub(:blacklight_config).and_return(CatalogController.blacklight_config)
    view.stub(:has_user_authentication_provider?).and_return(false)
  end

  it "should show more-like-this titles in the sidebar" do
  	@document = SolrDocument.new :id => 1, :title_s => 'abc', :format => 'default'
  	@document.stub(:more_like_this).and_return([SolrDocument.new({ 'id' => 2, 'title_display' => 'Title of MLT Document' })])
    render
    rendered.should include_text("More Like This")
    rendered.should include_text("Title of MLT Document")
  end
end