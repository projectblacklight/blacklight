require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe FolderController do
  before(:each) do
    request.env["HTTP_REFERER"] = "/"
  end
  
  it "should add items to list" do
    get :create, :id =>"77826928"
    session[:folder_document_ids].length.should == 1
    get :create, :id => "94120425"
    session[:folder_document_ids].length.should == 2
    session[:folder_document_ids].should include("77826928")
    get :index
    assigns[:documents].length.should == 2
    assigns[:documents].first.should be_instance_of(SolrDocument)
  end
  it "should delete an item from list" do
    get :create, :id =>"77826928"
    get :create, :id => "94120425"
    get :destroy, :id =>"77826928"
    session[:folder_document_ids].length.should == 1
    session[:folder_document_ids].should_not include("77826928")
  end
  it "should clear list" do
    get :create, :id =>"77826928"
    get :create, :id => "94120425"
    get :clear
    session[:folder_document_ids].length.should == 0
  end
end

