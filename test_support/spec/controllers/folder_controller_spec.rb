require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe FolderController do
  before(:each) do
    request.env["HTTP_REFERER"] = "/"
  end
  
  it "should add items to list" do
    get :update, :id =>"77826928"
    session[:folder_document_ids].length.should == 1
    get :update, :id => "94120425"
    session[:folder_document_ids].length.should == 2
    session[:folder_document_ids].should include("77826928")
    get :index
    assigns[:documents].length.should == 2
    assigns[:documents].first.should be_instance_of(SolrDocument)
  end
  it "should delete an item from list" do
    get :update, :id =>"77826928"
    get :update, :id => "94120425"
    get :destroy, :id =>"77826928"
    session[:folder_document_ids].length.should == 1
    session[:folder_document_ids].should_not include("77826928")
  end
  it "should clear list" do
    get :update, :id =>"77826928"
    get :update, :id => "94120425"
    get :clear
    session[:folder_document_ids].length.should == 0
  end

  it "should generate flash messages for normal requests" do
    get :update, :id => "77826928"
    flash[:notice].length.should_not == 0
  end
  it "should clear flash messages after xhr request" do
    xhr :get, :update, :id => "77826928"
    flash[:notice].should == nil
  end
end

