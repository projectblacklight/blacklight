require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BookmarksController do
  include Devise::TestHelpers
  let :user do
    User.create :email => 'mods_asset@example.com', :password => 'modsasset'
  end

  before(:each) do
    request.env["HTTP_REFERER"] = "/"

    sign_in user
  end

  it "should create bookmarks" do
    post "create", :bookmark => { :document_id => 'a' }
    Bookmark.last.document_id.should == 'a'
  end

  it "should create multiple bookmarks" do
    post "create", :bookmarks => [
       { :document_id => 'a' },
       { :document_id => 'b' }
    ]
    Bookmark.count.should == 2
  end

  it "should not create duplicate bookmarks" do
    post "create", :bookmark => { :document_id => 'a' }
    post "create", :bookmark => { :document_id => 'b' }
    post "create", :bookmark => { :document_id => 'a' }
    Bookmark.count.should == 2
  end

  it "should delete bookmarks" do
    post "create", :bookmark => { :document_id => 'a' }
    Bookmark.count.should == 1
    delete "destroy", :id => 'a'
    Bookmark.count.should == 0
  end

  it "should clear bookmarks" do
    post "create", :bookmark => { :document_id => 'a' }
    post "create", :bookmark => { :document_id => 'b' }
    delete "clear"
    Bookmark.count.should == 0
  end
end
